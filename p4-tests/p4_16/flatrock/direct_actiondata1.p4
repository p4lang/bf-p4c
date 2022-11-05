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

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    action noop() {}
    action setdata(bit<32> x1, bit<32> x2, bit<16> x3) {
        hdrs.data.f1 = x1;
        hdrs.data.f2 = x2;
        hdrs.data.h1 = x3;
    }

    table test1 {
        key = {
            hdrs.data.b1 : exact; 
        }
        actions = { noop; setdata; }
        size = 256;
        const default_action = noop();
    }

    apply {
        test1.apply();
    }
}

#include "common_t5na_test.p4h"
