#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

header a_t {
    bit<8> len;
}

header b_t {
    bit<8> data;
}

header c_t {
    bit<16> data;
}

header d_t {
    bit<24> data;
}

struct headers {
    a_t a;
    b_t b;
    c_t c;
    d_t d;
}

parser ParserImpl(packet_in pkt,
                  out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        pkt.extract(hdr.a);

        pctr.set(hdr.a.len);

        transition next_option;
    }

    @dont_unroll
    state next_option {
        transition select(pctr.is_zero()) {
            true : accept;  // no more option bytes left
            default : next_option_part2;
        }
    }

    state next_option_part2 {
        transition select(pkt.lookahead<bit<8>>()) {
            0xbb: parse_b;
            0xcc: parse_c;
            0xdd: parse_d;
            default: accept;
        }
    }

    // tests if compiler can detect that b, c and d are not mutex (due to loop)

    state parse_b {
        pkt.extract(hdr.b);
        pctr.decrement(1);
        transition next_option;
    }

    state parse_c {
        pkt.extract(hdr.c);
        pctr.decrement(2);
        transition next_option;
    }

    state parse_d {
        pkt.extract(hdr.d);
        pctr.decrement(3);
        transition next_option;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
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
