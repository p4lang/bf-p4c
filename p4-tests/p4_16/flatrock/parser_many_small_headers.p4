#include <t5na.p4>

header hdr_1_h {
    bit<8> b1;
}
header hdr_2_h {
    bit<8> b1;
}
header hdr_3_h {
    bit<8> b1;
}
header hdr_4_h {
    bit<8> b1;
}
header hdr_5_h {
    bit<8> b1;
}

struct headers {
    hdr_1_h h1;
    hdr_2_h h2;
    hdr_3_h h3;
    hdr_4_h h4;
    hdr_5_h h5;
}

struct metadata {
}

parser ingressParser(packet_in packet, out headers hdrs,
                     out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdrs.h1);
        packet.extract(hdrs.h2);
        packet.extract(hdrs.h3);
        packet.extract(hdrs.h4);
        packet.extract(hdrs.h5);
        transition accept;
    }
}

control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                       in egress_intrinsic_metadata_t eg_intr_md,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
        packet.emit(hdrs.h5);
        packet.emit(hdrs.h4);
        packet.emit(hdrs.h3);
        packet.emit(hdrs.h2);
        packet.emit(hdrs.h1);
    }
}

Pipeline(ingressParser(), ingress(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
