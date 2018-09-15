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
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

@name(".accum") register<pair32_t>(32w2048) accum;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp_1;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".sful") RegisterAction<pair32_t, bit<32>>(accum) sful = {
        void apply(inout         struct pair32_t {
            bit<32> lo;
            bit<32> hi;
        }
value, out bit<32> rv) {
            pair32_t in_value;
            in_value.lo = value.lo;
            in_value.hi = value.hi;
            rv = value.lo;
            value.hi = value.hi + 32w1;
            if (hdr.data.f2 > 32w1000 && hdr.data.f2 < 32w2000) 
                value.lo = value.lo + hdr.data.f3;
            if (hdr.data.f2 <= 32w1000 && hdr.data.f2 < 32w2000) 
                value.lo = in_value.lo - hdr.data.f3;
        }
    };
    @name(".act1") action act1_0(bit<9> port, bit<32> idx) {
        standard_metadata.egress_spec = port;
        tmp_1 = sful.execute(idx);
        hdr.data.f4 = tmp_1;
    }
    @name(".test1") table test1 {
        actions = {
            act1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction_0();
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

