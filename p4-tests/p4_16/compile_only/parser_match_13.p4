#if __TARGET_TOFINO__ >= 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

header a_t {
    bit<8>  x;
    bit<256> y;
    bit<8>  z;
}

header b_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  b1;
    bit<8>  n;
}

header c_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  n;
}

struct metadata {
}

struct headers {
    a_t a;
    b_t b;
    c_t c;
}

header ingress_skip_t {
#if __TARGET_TOFINO__ >= 2
    bit<192> pad;
#else
    bit<64> pad;
#endif
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
        transition select(hdr.a.x, hdr.a.z) {
            (0x4, 0x5) : parse_b;
            (0x6, 0x7) : parse_c;
            default : accept;
        }
    }

    state parse_b {
        b.extract(hdr.b);
        transition accept;
    }

    state parse_c {
        b.extract(hdr.c);
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
    apply { }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr.a);
        b.emit(hdr.b);
        b.emit(hdr.c);
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
