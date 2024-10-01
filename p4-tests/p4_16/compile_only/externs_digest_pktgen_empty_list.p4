// Once fixed, merge with externs_empty.list.p4.

#if   __TARGET_TOFINO__ == 1
#include "tna.p4"
#elif __TARGET_TOFINO__ == 2
#include "t2na.p4"
#elif __TARGET_TOFINO__ == 3
#include "t3na.p4"
#endif

header empty_header_h {}

struct metadata {}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply { }
}

#define INGRESS_DPRSR_OVERRIDE
control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {

    Digest<empty_header_h>() digest;
#if __TARGET_TOFINO__ > 1
    Pktgen() pktgen;
#endif  // __TARGET_TOFINO__ > 1

    apply {
        if (ig_intr_md_for_dprs.digest_type == 1) {
            digest.pack({});
        }
#if __TARGET_TOFINO__ > 1
        if (ig_intr_md_for_dprs.pktgen == 1) {
            pktgen.emit<empty_header_h>({});
        }
#endif  // __TARGET_TOFINO__ > 1
        packet.emit(hdr);
    }
}

#include "common_tna_test.h"

