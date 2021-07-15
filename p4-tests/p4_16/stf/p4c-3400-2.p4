#include <t2na.p4>       /* TOFINO2_ONLY */

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb2(bit<8> v) { hdr.data.b2 = v;}
    action noop() { }
    table test1 {
        key = {
            hdr.data.f1 : exact;
            hdr.data.f2 : exact;
        }
        actions = { noop; setb2; }
        const default_action = noop;
        size = 256*1024;  // big -- needs a bunch of stages
    }
    action setb1(bit<8> v) { hdr.data.b1 = v; }
    table test2 {
        key = {
            hdr.data.f1 : ternary;
            hdr.data.f2 : ternary;
        }
        actions = { noop; setb1; }
        const default_action = noop;
        size = 4*1024;
    }
    action seth1(bit<16> v) { hdr.data.h1 = v; }
    table test3 {
        key = {
            hdr.data.b1 : exact;
        }
        actions = { noop; seth1; }
        const default_action = noop;
        size = 256;
    }

    apply {
        if (ig_intr_md.ingress_port < 32) {
            test1.apply();
            if (ig_intr_md.ingress_port[0:0] == 0) {
                test2.apply();
            }
           test3.apply();
       }
       ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"
