#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<16>>(256) accum1;
    RegisterAction<bit<16>, bit<32>, bit<16>>(accum1) sful1 = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = value + (bit<16>)hdr.data.b1; } };
    register<bit<32>>(256) accum2;
    RegisterAction<bit<32>, bit<32>, bit<32>>(accum2) sful2 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = value;
            value = value + hdr.data.f2; } };

    apply {
        standard_metadata.egress_spec = 2;
        hdr.data.h1 = sful1.execute((bit<32>)hdr.data.b2);
        hdr.data.f1 = sful2.execute((bit<32>)hdr.data.b2);
    }
}

#include "common_v1_test.h"
