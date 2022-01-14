#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setf(bit<32> v1, bit<32> v2) {
        hdr.data.f1 = v1;
        hdr.data.f2 = v2;
    }
    /* table t1 here should use exactly two rams (one for match and one for action
     * data) -- need some way of checking the resulting .bfa for that? */
    table t1 {
        key = { hdr.data.h1[10:0] : exact @name("key"); }
        actions = { setf; }
        size = 2048;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
        t1.apply();
    }
}

#include "common_tna_test.h"
