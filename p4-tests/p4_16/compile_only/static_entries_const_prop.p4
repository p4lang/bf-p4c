#include <core.p4>
#include <tna.p4>

header a_t {
    bit<32> f1;
    bit<8>  b1;
    bit<8>  n;
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
    a_t d;
    b_t e;
    c_t f;
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
        transition select(hdr.a.n) {
            0x4 : parse_b;
            0x6 : parse_c;
            default : accept;
        }
    }

    state parse_b {
        b.extract(hdr.b);
        transition select(hdr.b.n) {
            0x2 : parse_d;
            default : accept;
        }
    }

    state parse_c {
        b.extract(hdr.c);
        transition select(hdr.c.n) {
            0x2 : parse_d;
            default : accept;
        }
    }

    state parse_d {
        b.extract(hdr.d);
        transition select(hdr.d.n) {
            0x4 : parse_e;
            0x6 : parse_f;
            default : accept;
        }
    }

    state parse_e {
        b.extract(hdr.e);
        transition accept;
    }

    state parse_f {
        b.extract(hdr.f);
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

    action rewrite_e() {
        hdr.e = hdr.b;
        hdr.b.setInvalid();
    }

    action rewrite_f() {
        hdr.f = hdr.c;
        hdr.c.setInvalid();
    }

    table rewrite {
        key = {
            hdr.b.isValid() : exact;
            hdr.c.isValid() : exact;
        }        

        actions = {
            rewrite_e;
            rewrite_f;
        }

        const entries = {
            { true, false } : rewrite_e();
            { false, true } : rewrite_f();
        }
    }

    action rewrite_b() {
        hdr.b = hdr.e;
        hdr.e.setInvalid();
    }

    action rewrite_c() {
        hdr.c = hdr.f;
        hdr.c.setInvalid();
    }

    table decap {
        key = {
            hdr.e.isValid() : exact;
            hdr.f.isValid() : exact;
        }

        actions = {
            rewrite_b;
            rewrite_c;
        }

        const entries = {
            { true, false } : rewrite_b();
            { false, true } : rewrite_c();
        }
    }


    apply {
        rewrite.apply();
        decap.apply();
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
        b.emit(hdr.c);
        b.emit(hdr.d);
        b.emit(hdr.e);
        b.emit(hdr.f);
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
