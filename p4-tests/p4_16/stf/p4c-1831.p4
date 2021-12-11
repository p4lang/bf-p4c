#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, _>(1) accum;
    RegisterAction<_, _, bit<16>>(accum) count = {
        void apply(inout bit<16> value, out bit<16> rv) {
            value = value + hdr.data.h1;
            rv = value; } };
    action doit() {
        ig_intr_tm_md.ucast_egress_port = 4;
        hdr.data.f1 = hdr.data.f1 + 0x1010101;
        hdr.data.f2 = hdr.data.f2 + 0xffff;
        hdr.data.h1 = count.execute(0);
    }
    apply {
        doit();
    }
}

#include "common_tna_test.h"
