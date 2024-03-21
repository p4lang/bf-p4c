#include <tna.p4>

struct metadata {
    bit<64> value;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.data);
        // Before fixing the issue, the first assignment had been dead-eliminated,
        // because the destination is the same as in the following assignment
        // (it hadn't been taking slicing into consideration).
        meta.value[31:0] = hdr.data.f1;
        meta.value[63:32] = hdr.data.f1;
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.data.f1 = meta.value[63:32];
        // Use the problematic slice to check that it has correct value
        // (otherwise, it would be zeroed).
        hdr.data.f2 = meta.value[31:0];
    }
}

#include "common_tna_test.h"
