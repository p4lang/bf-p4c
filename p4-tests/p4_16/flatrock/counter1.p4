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
    Counter<_,bit<12>>(4096, CounterType_t.PACKETS) ctr1;

    action noop() {}
    action increment(bit<12> idx) {
        ctr1.count(idx);
    }

    table test1 {
        key = {
            hdrs.data.f1 : exact; 
        }
        actions = { noop; increment; }
        size = 256;
        const default_action = noop();
    }

    apply {
        test1.apply();
    }
}

#include "common_t5na_test.p4h"
