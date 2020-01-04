#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata {}

struct pair {
    bit<16>  lo;
    bit<16>  hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<1>, bit<17>>(1 << 17, 1) array1;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };
    Register<pair, bit<12>>(1 << 12, { 10, 20 } ) array2;
    RegisterAction<pair, bit<12>, bit<16>>(array2) lookup = {
        void apply(inout pair data, out bit<16> rv) {
            if (hdr.data.h1 <= data.lo) {
                rv = data.hi;
                data.hi = data.hi + hdr.data.h1;
            } else {
                rv = 0;
            }
        }
    };

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        bit<1> t = filter1.execute(hdr.data.f1[16:0]);
        if (t == 1) {
            hdr.data.h1 = lookup.execute(hdr.data.f1[11:0]);
        }
    }
}

#include "common_tna_test.h"
