#include <core.p4>
#include <v1model.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action setb1(bit<8> val) { hdr.data.b1 = val; }
    action noop() { }
    table test {
        key = { hdr.data.f1: ternary; }
        actions = { setb1; noop; }
        default_action = setb1(0xaa); }

    apply {
        standard_metadata.egress_spec = 2;
        if (hdr.data.f2[27:20] == hdr.data.f1[27:20] && hdr.data.f2[11:4] == hdr.data.f1[11:4]) {
            test.apply(); } }
}

#include "common_v1_test.h"
