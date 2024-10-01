#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>, bit<16>>(65536) accum;
    RegisterAction<bit<16>, _, bit<16>>(accum) push = {
        void apply(inout bit<16> value, out bit<16> rv) {
            value = hdr.data.h1;
            rv = 0x0;
        }
    };
    RegisterAction<bit<16>, _, bit<16>>(accum) pop = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = 0xdead;
        }
    };

    apply {
        if (hdr.data.f1[31:31] == 0) {
            ig_intr_tm_md.ucast_egress_port = 2;
            hdr.data.h1 = push.push();
        } else {
            ig_intr_tm_md.ucast_egress_port = 4;
            hdr.data.h1 = pop.pop();
        }
    }
}

#include "common_t2na_test.h"
