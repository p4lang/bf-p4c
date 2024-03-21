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
    action setport(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action noop() { }

    @pack(1)
    table test1 {
        key = {
            // P4C-5003 - Fix Ixbar and match alignment issues seen for larger match key 
            hdrs.data.h1 : exact;
            hdrs.data.f1 : exact;
        }
        actions = { noop; setport; }
        size = 1024;
        const default_action = noop();
    }

    apply {
        // Commented out as this allocates to the table test1 to stage 1 which is giving issues
        // To be removed once the fix is in 
        // ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        // ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        test1.apply();
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
