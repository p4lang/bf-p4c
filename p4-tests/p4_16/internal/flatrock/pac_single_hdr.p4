// PAC (parde): single header
// --------------------------
//
// Summary:
//  - Single header
//  - Uses single analyzer stage
//  - Minimal PPU processing to use header
//
// Goals:
//  - basic check for parser extraction + deparser reconstruction.

#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h       data;
}

struct metadata {
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        bit<8> tmp;
        tmp = hdrs.data.b1;
        hdrs.data.b1 = hdrs.data.b2;
        hdrs.data.b2 = tmp;
    }
}

#include "common_t5na_test.p4h"

