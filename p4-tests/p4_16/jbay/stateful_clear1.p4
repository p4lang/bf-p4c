#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#error Unsupported target
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>, bit<16>>(65536) accum;
    RegisterAction<bit<16>, _, bit<16>>(accum) add = {
        void apply(inout bit<16> value, out bit<16> rv) {
            value = value + (bit<16>)hdr.data.b1;
            rv = value;
        }
    };

    apply {
        if (hdr.data.f1[31:31] == 0) {
            ig_intr_tm_md.ucast_egress_port = 1;
            hdr.data.h1 = add.execute(hdr.data.f1[15:0]);
        } else {
            ig_intr_tm_md.ucast_egress_port = 2;
            accum.clear(32, 0xde10);
        }
    }
}

#include "common_t2na_test.h"
