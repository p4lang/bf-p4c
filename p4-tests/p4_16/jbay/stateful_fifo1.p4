#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>>(2048) accum;
    RegisterAction<bit<16>, bit<16>>(accum) write = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };

    RegisterAction<bit<16>, bit<16>>(accum) read = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
        }
    };

    action enq(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.data.b1 = 0xff;
        write.enqueue();
    }
    table do_enq {
        actions = { enq; }
        key = { hdr.data.f1: ternary; }
    }

    action deq(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.data.b1 = 0xfe;
        hdr.data.h1 = read.dequeue();
    }
    table do_deq {
        actions = { deq; }
        key = { hdr.data.f1: exact; }
    }

    apply {
        if (hdr.data.b1 == 0) {
            do_deq.apply();
        } else {
            do_enq.apply();
        }
    }
}

#include "common_jna_test.h"
