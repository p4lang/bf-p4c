#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>, bit<13>>(8192) accum;
    MinMaxAction<bit<16>, bit<10>, bit<16>>(accum) rmax = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> idx) {
            idx = 0;
            rv = this.max16(value, 0xff, idx[2:0]);
        }
    };
    RegisterAction<bit<16>, bit<13>, bit<8>>(accum) load = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };

    action doload() {
        load.execute(hdr.data.f1[12:0]); }
    action domax() {
        bit<16> tmp;
        hdr.data.h1 = rmax.execute(hdr.data.f1[12:3], tmp);
        hdr.data.f1[2:0] = tmp[2:0]; }

    apply {
        if (hdr.data.b1 == 0)
            doload();
        else {
            ig_intr_tm_md.ucast_egress_port = 1;
            domax(); }
    }
}

#include "common_t2na_test.h"
