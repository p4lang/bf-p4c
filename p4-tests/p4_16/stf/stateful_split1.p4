#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, bit<12>>(4096) accum;
    RegisterAction<bit<16>, bit<12>, bit<16>>(accum) regact = {
        void apply(inout bit<16> value, out bit<16> res) {
            if (hdr.data.b1 == 0) {
                value = hdr.data.h1;
            } else {
                value = value + hdr.data.h1;
            }
            res = value; } };
    action act(bit<12> idx) { hdr.data.h1 = regact.execute(idx); }
    action noop() { }
    table test1 {
        key = { hdr.data.f1: exact; }
        actions = {
            act;
            @defaultonly noop;
        }
        const default_action = noop();
        size = 1024*1024;  // too big for one stage
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        test1.apply();
    }
}

#include "common_tna_test.h"
