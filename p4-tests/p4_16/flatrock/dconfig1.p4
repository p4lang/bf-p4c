#include <core.p4>
#include <t5na.p4>

// Needed until phv allocation can allocate the dconfig keymux field to B0..B4.
@pa_container_size("ingress", "hdrs.data.b1", 8)
header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<32>     f3;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h      data;
}
struct metadata {
    bit<8> sel;
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    action noop() {}
    action seth1(bit<16> v) {
        hdrs.data.h1 = v;
    }

    bit<32> table_key;
    table tbl {
        key = {
            table_key : exact @name("table_key");
            hdrs.data.h1 : exact;
        }
        actions = {
            noop();
            seth1();
        }
        size = 512;
        default_action = noop();
    }

    apply {
        if (hdrs.data.b1[0:0] == 1w0)
            table_key = hdrs.data.f1;
        else
            table_key = hdrs.data.f2;
        tbl.apply();
    }
}

#include "common_t5na_test.p4h"
