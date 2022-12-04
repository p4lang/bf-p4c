#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<32>     f3;
    bit<32>     f4;
    // bit<16>     h1;  // uncommenting this give parser errors
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
    action setb1(bit<8> v) { hdrs.data.b1 = v; }
    action setb2(bit<8> v) { hdrs.data.b2 = v; }

    table wide {
        key = {
            hdrs.data.f1 : ternary; 
            hdrs.data.f2 : ternary; 
            hdrs.data.f3 : ternary; 
            hdrs.data.f4 : ternary; 
        }
        actions = { noop; setb1; }
        size = 64;
        const default_action = noop();
    }

    table deep {
        key = {
            hdrs.data.f1 : ternary; 
        }
        actions = {
            noop;
            // setb1;  // uncommenting this causes incorrect action bus alloc
            setb2;
        }
        size = 4*1024;  // 10*1024 should fit but loops in tind alloc
        const default_action = noop();
    }

    apply {
        wide.apply();
        deep.apply();
    }
}

#include "common_t5na_test.p4h"
