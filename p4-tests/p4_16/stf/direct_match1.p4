#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb1(bit<8> v) { hdr.data.b1 = v; }
    /* table t1 here should use only one ram -- need some way of checking
     * the resulting .bfa for that? */
    table t1 {
        key = { hdr.data.h1[11:0] : exact @name("key"); }
        actions = { setb1; }
        size = 4096;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
        t1.apply();
    }
}

#include "common_tna_test.h"
