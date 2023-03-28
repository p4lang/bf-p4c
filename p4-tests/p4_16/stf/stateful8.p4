#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, bit<16>>(65536) accum;
    RegisterAction<bit<16>, bit<16>, bit<16>>(accum) ra_load = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1; } };
    RegisterAction<bit<16>, bit<16>, bit<16>>(accum) ra1 = {
        void apply(inout bit<16> value, out bit<16> rv) {
            if (hdr.data.b1 == 0)
                rv = min(hdr.data.h1, value);
            else
                rv = max(hdr.data.h1, value); } };
    RegisterAction<bit<16>, bit<16>, bit<16>>(accum) ra2 = {
        void apply(inout bit<16> value, out bit<16> rv) {
            if (hdr.data.b1 == 0)
                rv = hdr.data.h1 + value;
            else
                rv = hdr.data.h1 - value; } };
    action load() { ra_load.execute(hdr.data.f2[31:16]); }
    action act1() { hdr.data.f2[15:0] = ra1.execute(hdr.data.f2[31:16]); }
    action act2() { hdr.data.f2[15:0] = ra2.execute(hdr.data.f2[31:16]); }
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
