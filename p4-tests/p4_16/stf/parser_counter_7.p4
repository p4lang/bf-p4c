#if __TARGET_TOFINO__ == 1
#include <tna.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#error "Unsupported target"
#endif

struct metadata { }

header data_t {
    bit<8> f;
    bit<8> n;
}

struct headers {
    data_t a;
    data_t b;
    data_t c;
    data_t d;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);

#if __TARGET_TOFINO__ >= 2
        pctr.set(hdr.a.f, 8w255, 8w6, 8w255, 8w246);  // (max, rot, mask, add)
#else
        pctr.set(hdr.a.f, 8w255, 8w6, 3w7, 8w246);  // (max, rot, mask, add)
#endif

        transition select(hdr.a.n) {
            8w0xb: parse_b;
            default: accept;
        }
    }

    state parse_b {
        packet.extract(hdr.b);
        pctr.decrement(8w0x6);

        transition select(hdr.b.n) {
            8w0xc: parse_c;
            default: accept;
        }
    }

    state parse_c {
        packet.extract(hdr.c);
        transition select((bit<1>)pctr.is_zero()) {
            1w1: parse_d;
            default: accept;
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
    apply {
        if (hdr.d.isValid()) {
            ig_intr_tm_md.ucast_egress_port = 2;
        }
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
