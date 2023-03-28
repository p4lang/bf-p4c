#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<32>,PortId_t>(512) reg1;
    Register<bit<32>,PortId_t>(512) reg2;

    action a1() {
        reg1.write(ig_intr_md.ingress_port, hdr.data.f1);
        reg2.write(ig_intr_md.ingress_port, 0x03030303);
    }

    table t1 {
        actions = { a1; }
        const default_action = a1;
    }

    apply {
        t1.apply();
    }
}

#include "common_tna_test.h"
