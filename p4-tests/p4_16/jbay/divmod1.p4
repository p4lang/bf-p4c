#include <t2na.p4>

#define DATA_T_OVERRIDE 1
header data_t {
    bit<32>     f1;
    bit<16>     h1;
    bit<16>     h2;
    bit<16>     h3;
    bit<16>     h4;
}

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>>(2048) accum;
    RegisterAction<bit<16>, bit<16>>(accum) divmod = {
        void apply(inout bit<16> value, out bit<16> div, out bit<16> mod) {
            div = hdr.data.h1 / hdr.data.h2;
            mod = hdr.data.h1 % hdr.data.h2;
        }
    };

    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.data.h3 = divmod.execute(32w0, hdr.data.h4);
    }
}

#include "common_jna_test.h"
