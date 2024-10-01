#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
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
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"
