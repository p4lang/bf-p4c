#include <core.p4>
#include <v1model.p4>
#include <tofino/stateful_alu.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
}

struct metadata {
}

struct headers {
    data_t data;
}

struct pair {
    bit<16> first;
    bit<16> second;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<pair>(32w0) accum;
    DirectRegisterAction<pair, bit<16>>(accum) sful = {
        void apply(inout pair value, out bit<16> rv) {
            rv = value.first;
            if (hdr.data.h2 > value.first && hdr.data.h2 < value.second) {
                value.first = hdr.data.h3;
            }
            else {
                value.first = 0;
            }
            if (hdr.data.h2 >= value.second) {
                value.second = hdr.data.h3;
            }
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

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

