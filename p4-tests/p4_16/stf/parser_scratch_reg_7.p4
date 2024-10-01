/*******************************************************************************
 *
 *  parser_scratch_reg_7.p4
 *
 *  Targets: tofino2, tofino3
 *
 ******************************************************************************/
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <t2na.p4>
#endif

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header header_A_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_A0_t {
    bit<8>  f0;
    bit<8>  f1;
}

header header_A1_t {
    bit<8>  f0;
    bit<8>  f1;
}

header header_B_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_C_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_D_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_E_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_F_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_G_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_H_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_I_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

header header_J_t {
    bit<8>  f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
}

struct metadata_t {
}

struct header_t {
    ethernet_t          ethernet;
    header_A_t          header_a;
    header_A0_t         header_a0;
    header_A1_t         header_a1;
    header_B_t          header_b;
    header_C_t          header_c;
    header_D_t          header_d;
    header_E_t          header_e;
    header_F_t          header_f;
    header_G_t          header_g;
    header_H_t          header_h;
    header_I_t          header_i;
    header_J_t          header_j;
}

#define ETHER_TYPE_A0   0x9A0

// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHER_TYPE_A0: parse_header_a0;
            default: accept;
        }
    }

    state parse_header_a0 {
        pkt.extract(hdr.header_a);
        pkt.extract(hdr.header_a0);
        transition select(hdr.header_a.f0) {
            0xa0: parse_header_b;
            0xa1: parse_header_c;
            0x44: parse_header_b;
            0xa2: parse_header_c;
            default: accept;
        }
    }

    state parse_header_b {
        pkt.extract(hdr.header_b);
        transition select(hdr.header_b.f0) {
            0xb0 : parse_header_g;
            default: accept;
        }
    }

    state parse_header_c {
        pkt.extract(hdr.header_c);
        transition select(hdr.header_c.f0, hdr.header_c.f1, hdr.header_c.f2, hdr.header_c.f3) {
            (0x00, 0x01, 0x02, 0x03) : parse_header_g;
            (0xc0, 0xc1, 0xc2, 0xc3) : parse_header_d;
            (0xe0, 0xe1, 0xe2, 0xe3) : parse_header_g;
            (0xd0, 0xd1, 0xd2, 0xd3) : parse_header_d;
            default: accept;
        }
    }

    state parse_header_d {
        pkt.extract(hdr.header_d);
        transition select(hdr.header_a.f0, hdr.header_a.f1) {
            (0xa0, 0x01) : parse_header_g;
            (0xa1, 0xb1) : parse_header_f;
            (0xa2, 0xb2) : parse_header_f;
            default: accept;
        }
    }

    state parse_header_e {
        pkt.extract(hdr.header_e);
        transition select(hdr.header_e.f0) {
            0xb0 : parse_header_h;
            default: accept;
        }
    }

    state parse_header_f {
        pkt.extract(hdr.header_f);
        transition select(hdr.header_a.f0, hdr.header_a.f1, hdr.header_a.f2) {
            (0xa0, 0x01, 0x00) : parse_header_g;
            (0xa0, 0xaa, 0xbb) : parse_header_h;
            (0xa1, 0xb1, 0xc2) : parse_header_i;
            (0xa2, 0xb2, 0xc3) : parse_header_j;
            default : accept;
        }
    }

    state parse_header_g {
        pkt.extract(hdr.header_g);
        transition accept;
    }

    state parse_header_h {
        pkt.extract(hdr.header_h);
        transition accept;
    }

    state parse_header_i {
        pkt.extract(hdr.header_i);
        transition accept;
    }

    state parse_header_j {
        pkt.extract(hdr.header_j);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action header_a_fields_hit() {}

    table header_a_fields {
        key = {
            hdr.header_a.isValid(): exact;
            hdr.header_a.f0: exact;
            hdr.header_a.f1: exact;
            hdr.header_a.f2: exact;
            hdr.header_a.f3: exact;
        }
        actions = {
            header_a_fields_hit;
            NoAction;
        }
    }

    action header_a0_fields_hit() {}

    table header_a0_fields {
        key = {
            hdr.header_a0.isValid(): exact;
            hdr.header_a0.f0: exact;
            hdr.header_a0.f1: exact;
        }
        actions = {
            header_a0_fields_hit;
            NoAction;
        }
    }

    action header_a1_fields_hit() {}

    table header_a1_fields {
        key = {
            hdr.header_a1.isValid(): exact;
            hdr.header_a1.f0: exact;
            hdr.header_a1.f1: exact;
        }
        actions = {
            header_a1_fields_hit;
            NoAction;
        }
    }

    action header_b_fields_hit() {}

    table header_b_fields {
        key = {
            hdr.header_b.isValid(): exact;
            hdr.header_b.f0: exact;
            hdr.header_b.f1: exact;
            hdr.header_b.f2: exact;
            hdr.header_b.f3: exact;
        }
        actions = {
            header_b_fields_hit;
            NoAction;
        }
    }

    action header_c_fields_hit() {}

    table header_c_fields {
        key = {
            hdr.header_c.isValid(): exact;
            hdr.header_c.f0: exact;
            hdr.header_c.f1: exact;
            hdr.header_c.f2: exact;
            hdr.header_c.f3: exact;
        }
        actions = {
            header_c_fields_hit;
            NoAction;
        }
    }

    action header_d_fields_hit() {}

    table header_d_fields {
        key = {
            hdr.header_d.isValid(): exact;
            hdr.header_d.f0: exact;
            hdr.header_d.f1: exact;
            hdr.header_d.f2: exact;
            hdr.header_d.f3: exact;
        }
        actions = {
            header_d_fields_hit;
            NoAction;
        }
    }

    action header_e_fields_hit() {}

    table header_e_fields {
        key = {
            hdr.header_e.isValid(): exact;
            hdr.header_e.f0: exact;
            hdr.header_e.f1: exact;
            hdr.header_e.f2: exact;
            hdr.header_e.f3: exact;
        }
        actions = {
            header_e_fields_hit;
            NoAction;
        }
    }

    action header_f_fields_hit() {}

    table header_f_fields {
        key = {
            hdr.header_f.isValid(): exact;
            hdr.header_f.f0: exact;
            hdr.header_f.f1: exact;
            hdr.header_f.f2: exact;
            hdr.header_f.f3: exact;
        }
        actions = {
            header_f_fields_hit;
            NoAction;
        }
    }

    action header_g_fields_hit() {}

    table header_g_fields {
        key = {
            hdr.header_g.isValid(): exact;
            hdr.header_g.f0: exact;
            hdr.header_g.f1: exact;
            hdr.header_g.f2: exact;
            hdr.header_g.f3: exact;
        }
        actions = {
            header_g_fields_hit;
            NoAction;
        }
    }

    action header_h_fields_hit() {}

    table header_h_fields {
        key = {
            hdr.header_h.isValid(): exact;
            hdr.header_h.f0: exact;
            hdr.header_h.f1: exact;
            hdr.header_h.f2: exact;
            hdr.header_h.f3: exact;
        }
        actions = {
            header_h_fields_hit;
            NoAction;
        }
    }

    action header_i_fields_hit() {}

    table header_i_fields {
        key = {
            hdr.header_i.isValid(): exact;
            hdr.header_i.f0: exact;
            hdr.header_i.f1: exact;
            hdr.header_i.f2: exact;
            hdr.header_i.f3: exact;
        }
        actions = {
            header_i_fields_hit;
            NoAction;
        }
    }

    action header_j_fields_hit() {}

    table header_j_fields {
        key = {
            hdr.header_j.isValid(): exact;
            hdr.header_j.f0: exact;
            hdr.header_j.f1: exact;
            hdr.header_j.f2: exact;
            hdr.header_j.f3: exact;
        }
        actions = {
            header_j_fields_hit;
            NoAction;
        }
    }

    action header_i_parsed() {
        ig_tm_md.ucast_egress_port = 4;
    }

    action header_j_parsed() {
        ig_tm_md.ucast_egress_port = 6;
    }

    table header_parsed {
        key = {
            hdr.header_i.isValid(): exact;
            hdr.header_j.isValid(): exact;
        }
        actions = {
            header_i_parsed;
            header_j_parsed;
        }
        const entries = {
            (false, true) : header_j_parsed;
            (true, false) : header_i_parsed;
        }
    }

    apply {
        header_parsed.apply();
        header_a_fields.apply();
        header_a0_fields.apply();
        header_a1_fields.apply();
        header_b_fields.apply();
        header_c_fields.apply();
        header_d_fields.apply();
        header_e_fields.apply();
        header_f_fields.apply();
        header_g_fields.apply();
        header_h_fields.apply();
        header_i_fields.apply();
        header_j_fields.apply();
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t
                                ig_intr_dprsr_md
                              ) {
    apply {
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress Parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {}
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t
                                eg_intr_dprsr_md
                              ) {

    apply {
        pkt.emit(hdr);
    }
}


Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe;

Switch(pipe) main;
