#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h      data;
}
struct metadata {
}

#define HAVE_INGRESS
control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setport(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action noop() { }

    table test1 {
        key = {
            hdrs.data.f1 : exact;
            hdrs.data.h1 : exact;
        }
        actions = { noop; setport; }
        size = 128;
        const default_action = noop();
    }

    apply {
        ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        test1.apply();
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    action arithmetic() {
        hdrs.data.f1 = hdrs.data.f1 + 1;
        hdrs.data.h1 = hdrs.data.h1 + 1;
        hdrs.data.b1 = hdrs.data.b1 + 1;
    }
    action noop() { }
    table test2 {
        key = {
            hdrs.data.f1 : exact;
            hdrs.data.h1 : exact;
        }
        actions = { noop; arithmetic; }
        size = 128;
        const default_action = noop();
    }

    apply {
        test2.apply();
    }
}

#include "common_t5na_test.p4h"
