#include "t2na.p4"

@command_line("--infer-payload-offset")

struct metadata { }

// r = read-only
// w = writable
// u = unused

header a_t {
    bit<16> u1;
    bit<16> u2;
    bit<8> next;
}

header b_t {
    bit<16> u1;
    bit<16> u2;
    bit<16> w1;
    bit<16> u3;
    bit<16> r1;
    bit<8> next;
}

header c_t {
    bit<16> u1;
    bit<16> u2;
    bit<16> r1;
    bit<8> next;
}

header d_t {
    bit<16> r1;
    bit<16> u1;
    bit<16> r2;
    bit<8> next;
}

struct headers {
    a_t a;
    b_t b;
    c_t c;
    d_t d;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);

        packet.extract(hdr.a);

        transition select(hdr.a.next) {
            0xb : parse_b;
            0xc : parse_c;
        }
    }

    state parse_b {
        packet.extract(hdr.b);

        transition select(hdr.b.next) {
            0xc : parse_c;
            0xd : parse_d;
            default : accept;
        }
    }

    state parse_c {
        packet.extract(hdr.c);

        transition select(hdr.c.next) {
            0xd : parse_d;
            default : accept;
        }
    }

    state parse_d {
        packet.extract(hdr.d);

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() { }

    action a1(bit<16> val) {
        hdr.b.w1 = val;
    }

    table t1 {
        key = {
            hdr.b.r1 : exact;
            hdr.c.r1 : exact;
            hdr.d.r1 : exact;
            hdr.d.r2 : exact;
        }

        actions = { a1; noop; }
        default_action = noop;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 2;

        t1.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply { }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply { }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
