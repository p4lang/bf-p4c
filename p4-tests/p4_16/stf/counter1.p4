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

    action increment(bit<12> idx) {
        ctr1.count(idx);
        ctr2.count(idx);
    }
    action noop() {}
    table test1 {
        actions = {
            increment; noop;
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
