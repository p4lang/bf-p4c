#include <t2na.p4>

header a_t {
    bit<8> x;
    bit<8> y;
    bit<8> z;
}

header b_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  f3;
    bit<8>  f4;
}

header c_t {
    bit<8>  n;
}

header d_t {
    bit<16> f;
}

struct metadata {
}

struct headers {
    a_t a;
    b_t b;
    c_t c;
    d_t d;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(ig_intr_md);
        b.advance(192);
        b.extract(hdr.a);
        transition select(hdr.a.x) {
            0xb : parse_b;
            default : accept;
        }
    }

    state parse_b {
        b.extract(hdr.b);
        transition select(hdr.b.f1) {
            0xdeadbeef : parse_c;
            default : accept;
        }
    }

    state parse_c {
        b.extract(hdr.c);
        transition select(hdr.a.y) {
            0xd : parse_d;
            default : accept;
        }
    }

    state parse_d {
        b.extract(hdr.d);
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
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr);
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