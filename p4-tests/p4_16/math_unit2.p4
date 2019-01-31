#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, bit<16>>(1) accum;
    MathUnit<bit<16>>(MathOp_t.SQR, 1) square;
    RegisterAction<bit<16>, bit<1>, bit<16>>(accum) run = {
        void apply(inout bit<16> value, out bit<16> rv) {
            value = square.execute(hdr.data.h1);
            // Can't output the math unit directly -- math unit can only go in alu2-lo, which
            // writes to memory.
            rv = value; } };
    action noop() { }
    action do_run() { hdr.data.h1 = run.execute(0); }
    table test1 {
        actions = {
            noop;
            do_run;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        test1.apply();
    }
}

#include "common_tna_test.h"
