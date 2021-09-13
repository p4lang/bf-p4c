#include <tna.p4>

struct metadata { }

header data_t {
    bit<8> f;
}

header data_t16 {
    bit<16> f;
}

struct headers {
    data_t   h1;
    data_t16 h2;
    data_t   h3;
    data_t   h4;
}

struct headers2 {
    data_t h1;
}

parser PacketParser(      packet_in packet,
                    out   headers   hdr,
                    inout headers2  inout_hdr) {
    headers2 local_hdr2;

    state start {
        packet.extract(local_hdr2.h1);
        transition select(inout_hdr.h1.f) {
            0x20: local1;
            0x21: local2;
            default: accept;
        }
    }

    state local1 {
        packet.extract(hdr.h2);
        transition select(local_hdr2.h1.f) {
            0x31: parse_h4;
            default: accept;
        }
    }

    state local2 {
        packet.extract(hdr.h3);
        transition select(local_hdr2.h1.f) {
            0x41: parse_h4;
            default: accept;
        }
    }

    state parse_h4 {
        packet.extract(hdr.h4);
        transition accept;
    }
}

parser ingressParser(packet_in packet, out headers hdr,
                     out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParser() p;
    headers2 hdr2;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition select(ig_intr_md.ingress_port) {
            0: p_0;
            1: p_1;
            2: p_2;
            3: p_3;
            4: p_4;
            5: p_5;
            default: accept;
        }
    }

    state p_0 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        transition accept;
    }

    state p_1 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        transition select(hdr2.h1.f) {
            0x10: parse_h1;
            default: accept;
        }
    }

    state p_2 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        packet.extract(hdr.h1);
        transition accept;
    }

    state p_3 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        transition select(hdr2.h1.f) {
            0x10: parse_h1;
            default: accept;
        }
    }

    state p_4 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        transition accept;
    }

    state p_5 {
        packet.extract(hdr2.h1);
        p.apply(packet, hdr, hdr2);
        transition select(hdr2.h1.f) {
            0x11: parse_h1;
            default: accept;
        }
    }

    state parse_h1 {
        packet.extract(hdr.h1);
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
        } else if (hdr.h1.isValid()) {
            ig_intr_tm_md.ucast_egress_port = 1;
        } else {
            ig_intr_tm_md.ucast_egress_port = 9;
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