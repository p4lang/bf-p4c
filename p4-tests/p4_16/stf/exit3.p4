#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action set_port_and_exit(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        exit;
    }
    action noop() { }

    table test1 {
        key = { hdr.data.b1 : exact; }
        actions = { set_port_and_exit; noop; }
        const default_action = noop;
        const entries = {
            (1) : set_port_and_exit(2);
        }
        size = 2;
    }


    apply {
        test1.apply();
        ig_intr_tm_md.ucast_egress_port = 4;
    }
}

#include "common_tna_test.h"
