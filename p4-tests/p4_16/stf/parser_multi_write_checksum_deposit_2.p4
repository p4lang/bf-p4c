#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <tna.p4>
#endif

header data_t {
    bit<16> f;
}

struct metadata {
    data_t m;
}

struct headers {
    data_t a;
    data_t b;
    data_t c;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() checksum_1;
    Checksum() checksum_2;


    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);
        checksum_1.subtract(hdr.a);
        checksum_2.subtract(hdr.a);

        transition select(hdr.a.f) {
            0xffff:  accept;
            default: parse_b;
        }
    }

    state parse_b {
        packet.extract(hdr.b);
#if __TARGET_TOFINO__ == 1
        // expect error@-2: ".* previously assigned in state .*"
#endif

        transition select(hdr.b.f) {
            0xffff:  accept;
            default: parse_c;
        }
    }

    state parse_c {
        packet.extract(hdr.c);
        checksum_1.subtract(hdr.c);
        checksum_2.subtract(hdr.c);
        // overwrite header written in previous state that is not always overwritten here (it can
        // go to accept instead) -> error on TF1
        checksum_1.subtract_all_and_deposit(hdr.b.f);
#if __TARGET_TOFINO__ == 1
        // expect error@-2: "(in|e)gress::.* is assigned in state (in|e)gress::.* but has also previous assignment"
#endif
        meta.m.setValid();
        checksum_2.subtract_all_and_deposit(meta.m.f);

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (hdr.a.isValid() && hdr.b.isValid() && hdr.c.isValid()) {
            if (meta.m.f == hdr.b.f) {
                ig_intr_tm_md.ucast_egress_port = 2;
            } else {
                hdr.b.f = meta.m.f;
                ig_intr_tm_md.ucast_egress_port = 4;
            }
        } else {
            ig_intr_tm_md.ucast_egress_port = 0;
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
