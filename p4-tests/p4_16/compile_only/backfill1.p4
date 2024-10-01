#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action setout(PortId_t port) { ig_intr_tm_md.ucast_egress_port = port; }
    action setb1(bit<8> val) { hdr.data.b1 = val; }
    action seth1(bit<16> val) { hdr.data.h1 = val; }
    action noop() { }

    table t1 {
        key = { hdr.data.f2: exact; }
        actions = { setout; noop; }
        default_action = setout(1); }
    table t2 {
        key = { hdr.data.f1: exact; }
        actions = { setb1; noop; }
        default_action = setb1(0xaa); }
    table t3 {
        key = {
            hdr.data.f2: exact;
            hdr.data.b1: exact;
        }
        actions = { seth1; noop; }
        size = 1024 * 1024;
        default_action = noop(); }

    apply {
        t1.apply();
        // t2 will be higher priority (so placed first) due to longer dep chain, but the
        // dependent t3 can't go in the same stage, and t2 doesn't fill stage 0.  This pushes
        // t1 later (after t3), but we'd prefer to backfill t1 into the spare space in stage 0
        if (t2.apply().hit) {
            t3.apply();
        }
    }
}

#include "common_tna_test.h"
