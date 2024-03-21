#include <tna.p4>


struct metadata { }

header data_t {
    bit<8> f;
}

struct headers {
    data_t h1;
    data_t h2;
    data_t h3;
    data_t h4;
}

parser ingressParser(packet_in packet, out headers hdr,
                     out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.h1);
        pctr.set(hdr.h1.f);
        transition decrement_h2;
    }

    state decrement_h2 {
        packet.extract(hdr.h2);
        pctr.decrement(8w1);
        transition is_negative_h2;
    }

    state is_negative_h2 {
        transition select((bit<1>)pctr.is_negative()) {
            1w0: decrement_h3;
            default: accept;
        }
    }

    state decrement_h3 {
        packet.extract(hdr.h3);
        pctr.decrement(hdr.h2.f); // expect error: "Parser counter decrement argument is not a constant integer"
        transition is_negative_h3;
    }

    state is_negative_h3 {
        transition select((bit<1>)pctr.is_negative()) {
            1w0: parse_h4;
            default: accept;
        }
    }

    state parse_h4 {
        packet.extract(hdr.h4);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (hdr.h4.isValid()) {
            ig_intr_tm_md.ucast_egress_port = 4;
        } else if (hdr.h3.isValid()) {
            ig_intr_tm_md.ucast_egress_port = 3;
        } else if (hdr.h2.isValid()) {
            ig_intr_tm_md.ucast_egress_port = 2;
        } else {
            ig_intr_tm_md.ucast_egress_port = 10;
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

Pipeline(ingressParser(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
