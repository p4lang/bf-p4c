#include <tna.p4>

struct metadata { }

struct pair {
    bit<8>      lo;
    bit<8>      hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, _>(65536) accum;
    RegisterAction<_, _, bit<8>>(accum) ra_load = {
        void apply(inout pair value) {
            value.lo = hdr.data.b1;
            value.hi = hdr.data.b2; } };
    RegisterAction<_, _, bit<8>>(accum) ra1 = {
        void apply(inout pair value, out bit<8> rv) {
            rv = (bit<8>)(bit<1>)(hdr.data.b1 > value.lo && hdr.data.b1 < value.hi); } };
    RegisterAction<_, _, bit<8>>(accum) ra2 = {
        void apply(inout pair value, out bit<8> rv) {
            rv = hdr.data.b2 > value.lo && hdr.data.b2 < value.hi ? 8w1 : 8w0; } };
    action load() { ra_load.execute(hdr.data.h1); }
    action act1() { hdr.data.f2[7:0] = ra1.execute(hdr.data.h1); }
    action act2() { hdr.data.f2[7:0] = ra2.execute(hdr.data.h1); }
    table test1 {
        actions = {
            load;
            act1;
            act2;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        test1.apply();
    }
}

#include "common_tna_test.h"
