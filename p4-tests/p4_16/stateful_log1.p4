#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<16>>(2048) accum;
    RegisterAction<bit<16>, bit<32>, bit<16>>(accum) logh1 = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };

    RegisterAction<bit<16>, bit<32>, bit<16>>(accum) query = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
        }
    };

    action logit(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 0xff;
        logh1.execute_log();
    }
    table do_log {
        actions = { logit; }
        key = { hdr.data.f1: ternary; }
    }

    action getit(bit<11> index, bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 0xfe;
        hdr.data.h1 = query.execute((bit<32>)index);
    }
    table do_query {
        actions = { getit; }
        key = { hdr.data.f1: exact; }
    }

    apply {
        if (hdr.data.b1 == 0) {
            do_query.apply();
        } else {
            do_log.apply();
        }
    }
}

#include "common_v1_test.h"
