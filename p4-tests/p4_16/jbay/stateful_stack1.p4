#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, bit<16>>(2048) accum;
    RegisterAction<bit<16>, bit<16>, bit<16>>(accum) write = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };

    RegisterAction<bit<16>, bit<16>, bit<16>>(accum) read = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
        }
    };

    action push(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.data.b1 = 0xff;
        write.push();
    }
    table do_push {
        actions = { push; }
        key = { hdr.data.f1: ternary; }
    }

    action pop(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.data.b1 = 0xfe;
        hdr.data.h1 = read.pop();
    }
    table do_pop {
        actions = { pop; }
        key = { hdr.data.f1: exact; }
    }

    apply {
        if (hdr.data.b1 == 0) {
            do_pop.apply();
        } else {
            do_push.apply();
        }
    }
}

#include "common_jna_test.h"
