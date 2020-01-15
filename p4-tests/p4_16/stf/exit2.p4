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

    apply {
        if (hdr.data.b1 == 1) {
            if (hdr.data.b2 == 1) {
                hdr.data.b2 = 0xff;
            }
            ig_intr_tm_md.ucast_egress_port = 2;
            exit; }
        ig_intr_tm_md.ucast_egress_port = 3;
    }
}

#include "common_tna_test.h"
