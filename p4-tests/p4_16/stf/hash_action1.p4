#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action seth1(bit<16> v) { hdr.data.h1 = v; }
    @hash_action(1)
    table test {
        key = { hdr.data.b1 : exact; }
        actions = { seth1; }
        const default_action = seth1(0xffff);
        size = 256;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        if (hdr.data.f1[7:0] > 100)
            test.apply();
    }
}

#include "common_tna_test.h"
