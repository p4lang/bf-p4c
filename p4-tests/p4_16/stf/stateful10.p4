#include <tna.p4>

struct metadata { }

struct pair {
    bit<8>      lo;
    bit<8>      hi;
}
#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    pair    p;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, bit<16>>(65536) accum;
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra_init = {
        void apply(inout pair value) { value = { 1, 2 }; } };
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra_load = {
        void apply(inout pair value) { value = hdr.data.p; } };
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra1 = {
        void apply(inout pair value, out bit<8> rv) { rv = value.lo; } };
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra2 = {
        void apply(inout pair value, out bit<8> rv) { rv = value.hi; } };
    action init() { ra_init.execute(hdr.data.h1); }
    action load() { ra_load.execute(hdr.data.h1); }
    action act1() { hdr.data.f2[7:0] = ra1.execute(hdr.data.h1); }
    action act2() { hdr.data.f2[7:0] = ra2.execute(hdr.data.h1); }
    table test1 {
        actions = {
            init;
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
