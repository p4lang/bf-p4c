#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action noop() {}
    action setb1(bit<8> v, PortId_t port) {
        hdr.data.b1 = v;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table test1 {
        key = {
            hdr.data.f1 : exact; 
            hdr.data.h1 : exact; 
        }
        actions = { noop; setb1; }
        size = 8*1024;
        const default_action = noop();
    }

    apply {
        test1.apply();
    }
}

#include "common_tna_test.h"
