#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <tna.p4>
#endif

// Tests that multiple checksums can be placed into the same container, but on different positions

header data_t {
    bit<16> f;
}

// make sure the metadata bits get packed into the same container
@pa_byte_pack("ingress", 4, "err_4", "err_3", "err_2", "err_1")
struct metadata {
    bit<1> err_1;
    bit<1> err_2;
    bit<1> err_3;
    bit<1> err_4;
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
    Checksum() checksum_3;
    Checksum() checksum_4;

    state start {
        meta.err_1 = 0;
        meta.err_2 = 0;
        meta.err_3 = 0;
        meta.err_4 = 0;
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.a);
        checksum_1.add(hdr.a);

        transition select(hdr.a.f) {
            0xdead:  accept;
            default: parse_b;
        }
    }

    state parse_b {
        meta.err_1 = (bit<1>)checksum_1.verify();
        packet.extract(hdr.b);
        checksum_2.add(hdr.b);

        transition select(hdr.b.f) {
            0xdead:  accept;
            default: parse_c;
        }
    }

    state parse_c {
        meta.err_2 = (bit<1>)checksum_2.verify();
        packet.extract(hdr.c);
        checksum_3.add(hdr.c);

        transition select(hdr.c.f) {
            0xdead:  accept;
            default: parse_d;
        }
    }

    state parse_d {
        meta.err_3 = (bit<1>)checksum_3.verify();
        packet.extract(hdr.d);
        checksum_4.add(hdr.d);
        transition select(hdr.d.f) {
            0xdead:  accept;
            default: finalize;
        }
    }

    state finalize {
        meta.err_4 = (bit<1>)checksum_4.verify();
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (hdr.a.isValid() && hdr.b.isValid() && hdr.c.isValid() && hdr.d.isValid()) {
            if (meta.err_1 == 0 && meta.err_2 == 0 && meta.err_3 == 0 && meta.err_4 == 0) {
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
