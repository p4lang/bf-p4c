#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

@command_line("--decaf")

header a_t {
    bit<16> f;
}

header b_t {
    bit<16> f;
}

struct metadata {
}

struct headers {
    a_t a;
    b_t b;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
        b.extract(hdr.a);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action a0a0() {
        hdr.b.setValid();
        hdr.b.f = 0xa0a0;
    }

    action b0b0() {
        hdr.b.setValid();
        hdr.b.f = 0xb0b0;
    }

    action ffff() {
        hdr.b.setValid();
        hdr.b.f = 0xffff;
    }

    table add_header {
        key = {
            hdr.a.f : exact;
        }

        actions = {
            a0a0;
            b0b0;
            ffff;
        }
    }

    action set_port(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_tm_md.bypass_egress = 1w1;
    }

    table set_egress_port {
        actions = { set_port; }
        default_action = set_port(1);
    }

    apply {
        set_egress_port.apply();
        add_header.apply();
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr.a);
        b.emit(hdr.b);
    }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;  // XXX can't have empty parser in P4-16
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
