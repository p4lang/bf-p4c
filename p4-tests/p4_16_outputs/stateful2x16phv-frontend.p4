#include <core.p4>
#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata {
    @pa_container_size("ingress", "meta.a", 32) @pa_atomic("ingress", "meta.a") 
    bit<16> a;
    @pa_container_size("ingress", "meta.b", 32) @pa_atomic("ingress", "meta.b") 
    bit<16> b;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

struct pair {
    bit<16> lo;
    bit<16> hi;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp_0;
    @name("ingress.accum") register<pair>(32w2048) accum;
    @name("ingress.write") RegisterAction<pair, bit<16>>(accum) write_1 = {
        void apply(inout pair value) {
            value.lo = meta.a;
            value.hi = meta.b;
        }
    };
    @name("ingress.read") RegisterAction<pair, bit<16>>(accum) read_1 = {
        void apply(inout pair value, out bit<16> rv) {
            rv = value.hi;
        }
    };
    apply {
        standard_metadata.egress_spec = 9w3;
        meta.a = meta.a + hdr.data.f1[15:0];
        meta.b = meta.b + hdr.data.f2[15:0];
        if (hdr.data.b1 == 8w0) 
            write_1.execute((bit<32>)hdr.data.b2);
        else {
            tmp_0 = read_1.execute((bit<32>)hdr.data.b2);
            hdr.data.h1 = tmp_0;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
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

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

