#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

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
    RegisterAction<bit<8>, bit<16>, bit<8>>(accum) ra1 = {
        void apply(inout bit<8> value, out bit<8> rv) {
            bit<8> tmp;  // FIXME -- should not require explicit tmp
            if ((bool)hdr.data.b2[0:0])
                tmp = hdr.data.b1;
            else
                tmp = value;
            rv = tmp; } };
    RegisterAction<bit<8>, bit<16>, bit<8>>(accum) ra2 = {
        void apply(inout bit<8> value, out bit<8> rv) {
            rv = 0;
            if (value == hdr.data.b1) rv = rv | 1;
            // if (value == hdr.data.b2) rv = rv | 2; -- FIXME should be possible
            } };
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
        ig_intr_tm_md.ucast_egress_port = 3;
        test1.apply();
    }
}

#include "common_tna_test.h"
