#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#error Unsupported target
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                in ghost_intrinsic_metadata_t gmd) {

    action trigger() {
	ig_intr_dprsr_md.pktgen = 1w1;
	ig_intr_dprsr_md.pktgen_length = 10w512;
	ig_intr_dprsr_md.pktgen_address = 14w400;
    }
    table skip_packet {
        key = { hdr.data.f2 : exact; }
        actions = { trigger; } }

    apply {
	skip_packet.apply();
        ig_intr_tm_md.ucast_egress_port = 3;
    }
}

#include "common_t2na_test.h"
