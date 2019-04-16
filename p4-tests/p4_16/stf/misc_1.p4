#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

// trying to reproduce problem seen with global exec in switch_16

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action act1() {
        ig_intr_tm_md.ucast_egress_port = 1;
        hdr.data.h1 = 1; }
    action act2() {
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.data.h1 = 2; }
    action act3() {
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.h1 = 3; }
    action dep() { // unused, but causes dependencies between things
        hdr.data.f2[7:0] = hdr.data.f2[31:24]; }

    table t1 {
        actions = { act1; dep; }
        key = { hdr.data.f1: exact; }
    }
    @stage(1)
    table t2 {
        actions = { act2; dep; }
        key = { hdr.data.f1: exact; }
    }
    @stage(3)
    table t3 {
        actions = { act3; }
        key = { hdr.data.f1: exact; }
    }

    apply {
        hdr.data.f2[31:24] = 0;
        if (hdr.data.b1 == 0) {
            if (hdr.data.f2[31:31] == 0)
                t1.apply();
        } else {
            if (hdr.data.b2 == 0) {
                if (hdr.data.f2[31:31] == 0)
                    t2.apply();
            } else {
                if (hdr.data.f2[31:31] == 0)
                    t3.apply(); }
        }
    }
}

#include "common_tna_test.h"
