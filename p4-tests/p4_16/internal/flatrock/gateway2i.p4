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
    apply {
        if (hdrs.data.f2[27:20] == hdrs.data.f1[27:20] && hdrs.data.f2[11:4] == hdrs.data.f1[11:4]) {
            ig_intr_tm_md.ucast_egress_port = 4;
        } else {
            ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply { }
}

#include "common_t5na_test.p4h"
