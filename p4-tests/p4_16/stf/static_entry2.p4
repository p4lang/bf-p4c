#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb1(bit<8> v) { hdr.data.b1 = v; }
    table test {
        key = { hdr.data.h1 : exact; }
        actions = { setb1; }
        const default_action = setb1(0x01);
        const entries = {
            0x5555 : setb1(0x55);
            0x6666 : setb1(0x66);
            0x7777 : setb1(0x77);
            0x8888 : setb1(0x88);
        }
        size = 1;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        test.apply();
    }
}

#include "common_tna_test.h"
