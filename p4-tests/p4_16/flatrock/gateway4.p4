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
    apply {
            if (hdrs.data.h1 == 0 || hdrs.data.h1 == 1) {
                hdrs.data.b1[7:4] = 1;
            } else if (hdrs.data.h1 == 2 || hdrs.data.h1 == 4) {
                hdrs.data.b1[7:4] = 2;
            } else if (hdrs.data.h1 == 8 || hdrs.data.h1 == 16) {
                hdrs.data.b1[7:4] = 3;
            } else if (hdrs.data.h1 == 32 || hdrs.data.h1 == 64) {
                hdrs.data.b1[7:4] = 4;
            } else if (hdrs.data.h1 == 128 || hdrs.data.h1 == 256) {
                hdrs.data.b1[7:4] = 5;
            }
    }
}

#include "common_t5na_test.p4h"
