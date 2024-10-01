#if   __TARGET_TOFINO__ == 1
#include "tna.p4"
#elif __TARGET_TOFINO__ == 2
#include "t2na.p4"
#elif __TARGET_TOFINO__ == 3
#include "t3na.p4"
#endif

struct metadata {}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Hash<PortId_t>(HashAlgorithm_t.IDENTITY) hash;

    apply {
        ig_intr_tm_md.ucast_egress_port = hash.get({}); // expect error: "field list cannot be empty"
    }
}

#include "common_tna_test.h"

