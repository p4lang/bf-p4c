#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            noop;
        }
        key = {
            hdr.data.f1: ternary;
            hdr.data.f2: ternary;
            hdr.data.f3: ternary;
            hdr.data.f4: ternary;
            hdr.data.f5: ternary;
            hdr.data.f6: ternary;
            hdr.data.f7: ternary;
            hdr.data.b1: ternary;
            hdr.data.b2: ternary;
            hdr.data.b3: ternary;
            hdr.data.b4: ternary;
        }
    }
    @name(".test2") table test2 {
        actions = {
            noop;
        }
        key = {
            hdr.data.f1: ternary;
        }
    }
    @name(".test3") table test3 {
        actions = {
            noop;
        }
        key = {
            hdr.data.f3: ternary;
        }
    }
    @name(".test4") table test4 {
        actions = {
            noop;
        }
        key = {
            hdr.data.f1: ternary;
            hdr.data.b3: ternary;
        }
    }
    apply {
        test2.apply();
        test3.apply();
        test4.apply();
        test1.apply();
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
