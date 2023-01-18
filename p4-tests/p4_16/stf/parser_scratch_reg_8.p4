/*******************************************************************************
 *
 *  parser_scratch_reg_8.p4
 *
 *  Targets: tofino2, tofino3
 *
 ******************************************************************************/
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <t2na.p4>
#endif

header data_t {
    bit<8> f;
}

header data_wide_t {
    bit<32> f;
}

struct metadata {
}

struct headers {
    data_t a;
    data_t b;
    data_wide_t w;
    data_t c;
    data_t d;
    data_t e;
    data_t f;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<8> local;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);

        local = hdr.a.f;

        transition select(hdr.a.f) {
            8w0xa: parse_b;
            8w0xc: parse_c;
            default: accept;
        }
    }

    state parse_b {
        packet.extract(hdr.b);

        local = hdr.b.f;

        transition select(hdr.b.f) {
            8w0xb: parse_c;
            8w0x12: parse_wide_match;
            default: accept;
        }
    }

    state parse_wide_match {
        packet.extract(hdr.w);
        transition select(hdr.w.f) {
            32w0x1 : parse_d;
            32w0x2 : parse_c;
            default: accept;
        }
    }

    state parse_c {
        packet.extract(hdr.c);

        transition select(local) {
            0xf: parse_d;
            0xb: parse_e; // headers = a, b, c, e
            0xc: parse_f; // headers = a, c, f
            default: accept;
        }
    }

    state parse_d {
        packet.extract(hdr.d);
        transition accept;
    }

    state parse_e {
        packet.extract(hdr.e);
        transition accept;
    }

    state parse_f {
        packet.extract(hdr.f);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action path_a_b_c_e() {
        ig_intr_tm_md.ucast_egress_port = 6;
    }

    action path_a_c_f() {
        ig_intr_tm_md.ucast_egress_port = 8;
    }

    table check_parse_path {
        key = {
            hdr.a.isValid(): exact;
            hdr.b.isValid(): exact;
            hdr.c.isValid(): exact;
            hdr.e.isValid(): exact;
            hdr.f.isValid(): exact;
        }
        actions = {
            path_a_b_c_e;
            path_a_c_f;
            NoAction;
        }
        const entries = {
            (true, true, true, true, false) : path_a_b_c_e;
            (true, false, true, false, true) : path_a_c_f;
        }
        default_action = NoAction;
    }

    apply {
        check_parse_path.apply();
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
