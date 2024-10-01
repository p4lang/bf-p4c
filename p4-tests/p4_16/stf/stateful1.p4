#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<16>>(32w0) accum;
    DirectRegisterAction<bit<16>, bit<16>>(accum) sful = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = value + (bit<16>)hdr.data.b1;
        }
    };
    action addb1(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.h1 = sful.execute();
    }
    table test1 {
        actions = {
            addb1;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        test1.apply();
    }
}

#include "common_v1_test.h"
