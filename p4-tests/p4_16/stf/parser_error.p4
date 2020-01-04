#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

header h1_t {
    bit<16> ig_err;
    bit<16> eg_err;
    bit<16> len;
}

header h2_t {
    bit<512> data;
}

struct headers {
    h1_t h1;
    h2_t h2;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.h1);
        transition select (hdr.h1.ig_err) {
             0x0: parse_h2;
             default: accept;
        }
    }

    state parse_h2 {
        packet.extract(hdr.h2);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action send_back() {
        hdr.h1.ig_err = ig_intr_prsr_md.parser_err;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
    table t1 {
        actions = {
            send_back();
        }
        size = 1;
        default_action = send_back();
    }

    apply {
        t1.apply();
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
