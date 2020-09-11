#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Counter<_,bit<12>>(4096, CounterType_t.PACKETS) ctr1;
    Counter<_,bit<12>>(4096, CounterType_t.PACKETS) ctr2;

    // enable is part of the addressing, so can't have different enables for the two
    // counters in one action
    action incr1(bit<12> idx) { ctr1.count(idx); }
    action incr2(bit<12> idx) { ctr2.count(idx); }
    action noop() {}
    table test1 {
        actions = {
            incr1; incr2; noop;
        }
        key = {
            hdr.data.f1: exact;
        }
        default_action = noop;
    }
    apply {
        test1.apply();
    }
}

#include "common_tna_test.h"
