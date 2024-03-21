#include <t5na.p4>
#define HAVE_INGRESS 1

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h      data;
}
struct metadata {
}

control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {}
    action setport(bit<7> p) {
        ig_intr_tm_md.ucast_egress_port = p;
    }

    table test1 {
        key = {
            hdrs.data.f1 : ternary;
	    hdrs.data.f2 : ternary;
	    hdrs.data.h1 : ternary;
	    hdrs.data.isValid() : ternary;
        }
        actions = { noop; setport; }
        size = 2048;
        const default_action = noop();
    }

    apply {
        ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
	test1.apply();
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    action noop() {}
    action setb1(bit<8> v) {
        hdrs.data.b1 = v;
    }
    action setf1(bit<8> v) {
        hdrs.data.f1[7:0] = v;
    }

    table test1 {
        key = {
            hdrs.data.f1[7:0] : ternary;
	    hdrs.data.f2[15:8] : ternary;
	    hdrs.data.h1[15:8] : ternary;
	    hdrs.data.b1 : ternary;
	    hdrs.data.isValid() : ternary;
        }
        actions = { noop; setb1; }
        size = 2048;
        const default_action = noop();
    }
    table test2 {
        key = {
            hdrs.data.f1 : ternary;
	    hdrs.data.f2 : ternary;
	    hdrs.data.h1 : ternary;
	    hdrs.data.isValid() : ternary;
        }
        actions = { noop; setf1; }
        size = 512;
        const default_action = noop();
    }
    table test3 {
        key = {
            hdrs.data.f1 : ternary;
	    hdrs.data.f2 : ternary;
        }
        actions = { noop; setf1; }
        size = 4096;
        const default_action = noop();
    }

    apply {
        test1.apply();
	test2.apply();
	test3.apply();
    }
}

#include "common_t5na_test.p4h"
