#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<32>, bit<32>>(1) accum;
    MathUnit<bit<32>>(MathOp_t.MUL, 1, 10) mu; // divide by 10
    RegisterAction<bit<32>, bit<1>, bit<32>>(accum) div10 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            value = mu.execute(hdr.data.f2);
            // Can't output the math unit directly -- math unit can only go in alu2-lo, which
            // writes to memory.
            rv = value; } };
    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        hdr.data.f2 = div10.execute(0);
    }
}

#include "common_tna_test.h"
