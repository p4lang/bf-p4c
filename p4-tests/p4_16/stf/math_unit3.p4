#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<32>, bit<32>>(1) accum;
    MathUnit<bit<32>>(MathOp_t.RSQRT, 0x1000000) rsqrt; // scaled 16.16 fixed point
    RegisterAction<bit<32>, bit<1>, bit<32>>(accum) run = {
        void apply(inout bit<32> value, out bit<32> rv) {
            value = rsqrt.execute(hdr.data.f2);
            // Can't output the math unit directly -- math unit can only go in alu2-lo, which
            // writes to memory.
            rv = value; } };
    action noop() { }
    action do_run() { hdr.data.f2 = run.execute(0); }
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
