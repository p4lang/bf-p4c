#include <t2na.p4>

/* corner case test for long branch and mpr -- long branch between table A an B where
 * B is in an action-dependent stage, and there's a match dependent stage between them */

// force all PHVs to normal (no mocha) as using mocha containers makes stages match dependent
@pa_container_type("ingress", "hdr.data.f1", "normal")
@pa_container_type("ingress", "hdr.data.f2", "normal")
@pa_container_type("ingress", "hdr.data.h1", "normal")
@pa_container_type("ingress", "hdr.data.b1", "normal")
@pa_container_type("ingress", "hdr.data.b2", "normal")

struct metadata { }

#include "trivial_parser.h"


control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                in ghost_intrinsic_metadata_t gmd) {

    action setb1(bit<8> val) { hdr.data.b1 = val; }
    action addb1(bit<8> val) { hdr.data.b1 = hdr.data.b1 + val; }
    action seth1(bit<16> val) { hdr.data.h1 = val; }
    action nop() {}

    table A {
        key = { hdr.data.f1 : exact; }
        actions = { setb1; nop; }
        default_action = nop;
    }
    @stage(4)
    table B {
        key = { hdr.data.f2 : exact; }
        actions = { seth1; }
        default_action = seth1(0x0000);
    }
    @stage(5)
    table C {
        key = { hdr.data.f2 : exact; }
        actions = { seth1; }
        default_action = seth1(0xffff);
    }


    apply {
        if (A.apply().hit) {
            B.apply();
        } else {
            C.apply();
        }
        addb1(2);
        if (hdr.data.b1 >= 128)
            addb1(4);
        ig_intr_tm_md.ucast_egress_port = 4;
    }
}

#include "common_t2na_test.h"
