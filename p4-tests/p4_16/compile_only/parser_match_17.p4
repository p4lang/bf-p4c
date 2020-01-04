#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

header data_t {
    bit<4> f;
    bit<4> p;
    bit<8> n;
    bit<32> x;
}

struct headers {
    data_t a;
    data_t b;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);
        pctr.set(hdr.a.f);

        transition select(pctr.is_zero(), hdr.a.x) {
            { false, 32w1 }: parse_b;
            default: accept;
        }
    }

    state parse_b {
        packet.extract(hdr.b);
        transition accept; 
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
