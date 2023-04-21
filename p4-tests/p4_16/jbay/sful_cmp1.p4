#include <t2na.p4>

struct metadata { }

struct pair {
    bit<32>     lo;
    bit<32>     hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, bit<12>>(4096) accum;
    RegisterAction<pair, bit<12>, bit<32>>(accum) ra_load = {
        void apply(inout pair value) {
            value.lo = hdr.data.f1;
            value.hi = hdr.data.f2; } };
    RegisterAction<pair, bit<12>, bit<32>>(accum) ra1 = {
        void apply(inout pair value, out bit<32> rv) {
            if (value.lo > hdr.data.f1 &&
                (value.lo < hdr.data.f2 ||
                 value.hi > hdr.data.f1 && value.hi < hdr.data.f2)) {
                value.lo = value.lo - hdr.data.f1;
                rv = value.lo;
            } else {
                value.hi = value.hi | hdr.data.f2;
                rv = 0;
            }
        }
    };

    action load() { ra_load.execute(hdr.data.h1[11:0]); }
    action act1() { hdr.data.f2 = ra1.execute(hdr.data.h1[11:0]); }
    table test1 {
        actions = {
            load;
            act1;
        }
        key = {
            hdr.data.b1: exact;
        }
        size = 256;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        test1.apply();
    }
}

#include "common_t2na_test.h"
