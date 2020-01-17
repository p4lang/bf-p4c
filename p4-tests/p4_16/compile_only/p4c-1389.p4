#include <tna.p4>

struct metadata {}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Counter<bit<32>,_>(4096, CounterType_t.PACKETS) cntr;

    action count(bit<12> idx) { cntr.count(idx); }
    action noop() { }

    table t1 {
        key = { hdr.data.f1 : exact; }
        actions = { count; noop; }
        const default_action = noop;  // removing the const will cause an error
    }
    table t2 {
        key = { hdr.data.f2 : exact; }
        actions = { count; noop; }
        const default_action = noop;
    }

    apply {
        if (!t1.apply().hit) {
            t2.apply();
        }
    }
}

#include "common_tna_test.h"
