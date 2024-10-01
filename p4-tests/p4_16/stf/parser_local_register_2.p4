#include <tna.p4>

header data_t {
    bit<16> f;
}

struct metadata {
    bool m_parse_e;
    bool m_parse_f;
}

struct headers {
    data_t a;
    data_t b;
    data_t c;
    data_t d;
    data_t e;
    data_t f;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<16> local;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);
        local = packet.lookahead<bit<16>>();
        transition select(hdr.a.f[7:0]) {
            8w0x11: parse_b;
            8w0x55: parse_c;
            default: accept;
        }
    }

    state parse_b {
        hdr.b.f = local;
        hdr.b.setValid();
        transition parse_d;
    }

    state parse_c {
        packet.extract(hdr.c);
        local = hdr.c.f;
        transition parse_d;
    }

    state parse_d {
        packet.extract(hdr.d);
        transition select(local[7:0]) {
           0x22 : parse_e;
           0x66 : parse_f;
        }
    }
    state parse_e {
        packet.extract(hdr.e);
        local = hdr.e.f;
        meta.m_parse_e = true;
        transition accept;
    }
    state parse_f {
        packet.extract(hdr.f);
        meta.m_parse_f = true;

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (meta.m_parse_e) {
            hdr.e.f = 0xEEEE;
        } else if (meta.m_parse_f) {
           hdr.f.f = 0xFFFF;
        }
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
