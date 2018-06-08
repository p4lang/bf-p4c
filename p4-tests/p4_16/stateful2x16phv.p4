#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata {
    @pa_container_size("ingress", "meta.a", 32)
    @pa_atomic("ingress", "meta.a")
    bit<16>     a;
    @pa_container_size("ingress", "meta.b", 32)
    @pa_atomic("ingress", "meta.b")
    bit<16>     b;
}
#define METADATA_INIT(M) M.a = 0; M.b = 0;

#include "trivial_parser.h"

struct pair {
    bit<16>     lo;
    bit<16>     hi;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<pair>(2048) accum;
    RegisterAction<pair, bit<16>>(accum) write = {
        void apply(inout pair value) {
            value.lo = meta.a;
            value.hi = meta.b;
        }
    };
    RegisterAction<pair, bit<16>>(accum) read = {
        void apply(inout pair value, out bit<16> rv) {
            rv = value.hi;
        }
    };

    apply {
        standard_metadata.egress_spec = 3;
        meta.a = meta.a + hdr.data.f1[15:0];
        meta.b = meta.b + hdr.data.f2[15:0];
        if (hdr.data.b1 == 0) {
            write.execute((bit<32>)hdr.data.b2);
        } else {
            hdr.data.h1 = read.execute((bit<32>)hdr.data.b2);
        }
    }
}

#include "common_v1_test.h"
