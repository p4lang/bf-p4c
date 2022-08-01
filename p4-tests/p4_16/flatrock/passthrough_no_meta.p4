// Modified passthrough.p4 program
// 
// This version does *not* copy ingress port info to egress. Withouth this
// copy, the compiler will attempt to optimize ingress metadata away.
// This leads to a "Null field" compiler error being reported if the metadata
// packer valid vector fields are not kept.

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
        apply { }
    }

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        hdrs.data.f1 = hdrs.data.f2;
    }
}

#include "common_t5na_test.p4h"
