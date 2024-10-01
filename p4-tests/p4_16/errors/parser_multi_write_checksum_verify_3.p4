#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <tna.p4>
#endif

header data_t {
    bit<15> f;
    bool b;
}

struct metadata {
    data_t m;
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
    Checksum() checksum_1;
    Checksum() checksum_2;


    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);
        checksum_1.add(hdr.a);
        checksum_2.add(hdr.a);

        transition select(hdr.a.f) {
            0x7fff:  accept;
            default: parse_b;
        }
    }

    state parse_b {
        packet.extract(hdr.b);
#if __TARGET_TOFINO__ == 1
        // expect error@-2: ".* previously assigned in state .*"
#endif
        checksum_1.add(hdr.b);
        checksum_2.add(hdr.b);

        transition select(hdr.b.f) {
            0x7fff:  accept;
            default: parse_c;
        }
    }

    state parse_c {
        packet.extract(hdr.c);
        checksum_1.add(hdr.c);
        checksum_2.add(hdr.c);
        // there is an overwrite, of part of the byte set in a previous state that cannot be
        // dead-code-eliminated because the parser can go into a different branchy that does not
        // end here
        // This is a problem for all tofino version as we can't do sub-byte overwrite, only
        // bitwise or.
        hdr.b.b = checksum_1.verify(); // overwrite -> error
#if __TARGET_TOFINO__ == 1
        // expect error@-2: "(in|e)gress::.* is assigned in state (in|e)gress::.* but has also previous assignment"
#else
        /* expect error@-4: "Using checksum verify in direct assignment to set .*; is not supported \
when the left-hand side of the assignment can be written multiple times for one packet\." */
#endif
        meta.m.setValid();
        meta.m.b = checksum_2.verify();

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
            hdr.d.setValid();
            if (meta.m.b) {
                hdr.d.f = 0x7fff;
            } else {
                hdr.d.f = 0;
            }
            hdr.d.b = hdr.b.b;

            if (meta.m.b == hdr.b.b) {
                ig_intr_tm_md.ucast_egress_port = 2;
            } else {
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
