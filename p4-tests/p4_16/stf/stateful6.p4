#include <tna.p4>

struct metadata { }

struct pair {
    bit<16>      lo;
    bit<16>      hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, bit<16>>(65536) accum;
    RegisterAction<pair, bit<16>, bit<16>>(accum) ra_load = {
        void apply(inout pair value) {
            value.lo = hdr.data.f2[15:0];
#if __TARGET_TOFINO__ >= 3
            value.hi = hdr.data.f2[19:16] ++ 1w0 ++ ig_intr_md.ingress_port;
#else
            value.hi = hdr.data.f2[19:16] ++ 3w0 ++ ig_intr_md.ingress_port;
#endif
        } };
    RegisterAction<pair, bit<16>, bit<16>>(accum) ra1 = {
        void apply(inout pair value, out bit<16> rv) {
            rv = value.hi; } };
    RegisterAction<pair, bit<16>, bit<16>>(accum) ra2 = {
        void apply(inout pair value, out bit<16> rv) {
            rv = value.lo; } };
    action load() { ra_load.execute(hdr.data.h1); }
    action act1() { hdr.data.f2[9:0] = ra1.execute(hdr.data.h1)[9:0]; }
    action act2() { hdr.data.f2[3:0] = ra1.execute(hdr.data.h1)[15:12]; }
    action act3() { hdr.data.f2[15:0] = ra2.execute(hdr.data.h1); }
    table test1 {
        actions = {
            load;
            act1;
            act2;
            act3;
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
