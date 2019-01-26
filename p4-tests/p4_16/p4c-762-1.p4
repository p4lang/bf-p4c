#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
        standard_metadata.egress_spec = 2;
        hdr.data.b1 = hdr.data.b1 + hdr.data.b2;
        hdr.data.b1 = hdr.data.b1 + hdr.data.h1[7:0];
        hdr.data.b1 = hdr.data.b1 + hdr.data.h1[15:8];
    }
}

#include "common_v1_test.h"
