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
    RegisterAction<bit<16>, bit<1>, bit<16>>(accum) run = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = hdr.data.b2 ++ hdr.data.b1; } };
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.h1 = run.execute(0);
    }
}

#include "common_tna_test.h"