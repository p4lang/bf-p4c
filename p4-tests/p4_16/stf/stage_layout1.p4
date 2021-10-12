#include <tna.p4>

struct metadata { }

// trying to reproduce problem seen with global exec in switch_16

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action noop() {}
    action act1(bit<16> val) {
        ig_intr_tm_md.ucast_egress_port = (PortId_t)val;
        hdr.data.h1 = val; }

    @stage(1, 4096, "noimmediate")
    @stage(2, 4096, "immediate")
    @stage(3, 4096, "noimmediate")
    table t1 {
        actions = { noop; act1; }
        key = { hdr.data.f1: exact; }
            size = 12*1024;
    }

    apply {
        t1.apply();
    }
}

#include "common_tna_test.h"
