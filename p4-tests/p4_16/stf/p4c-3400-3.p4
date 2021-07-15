#include <t2na.p4>       /* TOFINO2_ONLY */

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb2(bit<8> v) { hdr.data.b2 = v; }
    action noop() { }
    table test1 {
        key = {
            hdr.data.f1 : exact;
            hdr.data.f2 : exact;
        }
        actions = { noop; setb2; }
        const default_action = noop;
        size = 320*1024;  // big -- needs a bunch of stages
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

    apply {
        if (ig_intr_md.ingress_port < 32) {
            switch (test1.apply().action_run) {
		setb2: { hdr.data.h1 = hdr.data.h1 + 1; }
		default: { hdr.data.h1 = hdr.data.h1 + 2; }
	    }
            if (ig_intr_md.ingress_port[0:0] == 0) {
                test2.apply();
            }
        }
	ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"

