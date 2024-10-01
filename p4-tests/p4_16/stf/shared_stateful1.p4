#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<8>, bit<16>>(65536) accum;
    RegisterAction<bit<8>, bit<16>, bit<8>>(accum) ra_load = {
        void apply(inout bit<8> value) { value = hdr.data.b1; } };
    RegisterAction<bit<8>, bit<16>, bit<8>>(accum) ra_add = {
        void apply(inout bit<8> value, out bit<8> rv) {
            rv = value;
            value = value + hdr.data.b1; } };
    action nop() {}
    action load() { ra_load.execute(hdr.data.h1); }
    action radd() { hdr.data.f2[7:0] = ra_add.execute(hdr.data.h1); }
    table test1 {
        actions = { nop; load; }
        key = { hdr.data.f1: ternary; }
        const default_action = nop();
    }
    table test2 {
        actions = { nop; radd; }
        key = { hdr.data.f1: ternary; }
        const default_action = nop();
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        if (test1.apply().miss) {
            test2.apply();
        }
    }
}

#include "common_tna_test.h"
