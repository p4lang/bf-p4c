#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> tmp;
}

struct pair32_t {
    bit<32> lo;
    bit<32> hi;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".data") 
    data_t data;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

@name(".accum") register<pair32_t>(32w65536) accum;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".sful") RegisterAction<pair32_t, bit<32>>(accum) sful = {
        void apply(inout         struct pair32_t {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            rv = 32w0;
            pair32_t in_value;
            in_value = value;
            rv = in_value.lo;
            value.hi = in_value.hi + 32w1;
            if (hdr.data.f2 > 32w1000 && hdr.data.f2 < 32w2000) 
                value.lo = in_value.lo + hdr.data.f3;
            if (!(hdr.data.f2 > 32w1000) && hdr.data.f2 < 32w2000) 
                value.lo = in_value.lo - hdr.data.f3;
        }
    };
    @name(".act1") action act1(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.f4 = sful.execute((bit<32>)hdr.data.h1 + 32w0);
    }
    @name(".test1") table test1 {
        actions = {
            act1;
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

