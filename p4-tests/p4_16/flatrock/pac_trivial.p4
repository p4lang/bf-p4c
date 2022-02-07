// PAC (parde): trivial
// --------------------
//
// Summary:
//  - No headers
//  - Parser generates metadata only
//  - No PPU processing except setting output port
//
// Goals:
//  - Bootstrap test to get things through parser/deparser (PAC) passes.

#include <t5na.p4>

// Don't attempt to extract any headers
#define PRSR_SKIP_HDR_EXTRACT

struct headers {
}

struct metadata {
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply { }
}

#include "common_t5na_test.p4h"

