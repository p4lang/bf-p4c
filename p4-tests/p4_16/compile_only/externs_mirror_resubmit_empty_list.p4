#if   __TARGET_TOFINO__ == 1
#include "tna.p4"
#elif __TARGET_TOFINO__ == 2
#include "t2na.p4"
#elif __TARGET_TOFINO__ == 3
#include "t3na.p4"
#endif

header empty_header_h {}

struct metadata {
    MirrorId_t mirror_session;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    apply {
        meta.mirror_session = 1;
    }
}

#define INGRESS_DPRSR_OVERRIDE
control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {

    Mirror() mirror;
    Resubmit() resubmit;

    apply {
        if (ig_intr_md_for_dprs.mirror_type == 1) {
            mirror.emit<empty_header_h>(meta.mirror_session, {});
        }
        if (ig_intr_md_for_dprs.resubmit_type == 1) {
            resubmit.emit<empty_header_h>({});
        }
        packet.emit(hdr);
    }
}

#include "common_tna_test.h"

