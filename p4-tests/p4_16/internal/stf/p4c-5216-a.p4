#include <t2na.p4>

struct metadata {
    bit<1>  flag;
}


#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<8>, bit<16>>(65536, 0) reg;
    RegisterAction<bit<8>, bit<16>, bit<8>>(reg) ra_load = {
        void apply(inout bit<8> data, out bit<8> rv) {
            rv = data;
            data = hdr.data.b1; } };
    RegisterAction<bit<8>, bit<16>, bit<8>>(reg) ra1 = {
        void apply(inout bit<8> data, out bit<8> rv) {
            rv = data; } };

    action load() { ra_load.execute(hdr.data.h1); }
    action act1() {
        bit<8> tmp = ra1.execute(hdr.data.h1);
        hdr.data.b2 = tmp;
        meta.flag = meta.flag & tmp[7:7]; }
    table test1 {
        actions = {
            load;
            act1;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 256;
    }
    apply {
        meta.flag = 1;
        ig_intr_tm_md.ucast_egress_port = 4;
        test1.apply();
        if (meta.flag == 1) {
            hdr.data.f2[15:12] = 0;
        }
    }
}

#include "common_tna_test.h"
