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
    action setb1(bit<8> v) {
        hdrs.data.b1 = v;
    }

    table test1 {
        key = {
            hdrs.data.f1 : exact; 
        }
        actions = { noop; setb1; }
        size = 32;
        const default_action = setb1(0xaa);
    }

    apply {
        if (hdrs.data.f2[27:20] == hdrs.data.f1[27:20] && hdrs.data.f2[11:4] == hdrs.data.f1[11:4])
            test1.apply();
    }
}

#include "common_t5na_test.p4h"
