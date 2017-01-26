#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
}

struct headers {
    @name("data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_1") action NoAction_0() {
    }
    @name("NoAction_2") action NoAction_4() {
    }
    @name("NoAction_3") action NoAction_5() {
    }
    @name("noop") action noop_0() {
    }
    @name("test1") table test1() {
        actions = {
            noop_0();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.f1: ternary;
            hdr.data.f2: ternary;
            hdr.data.b1: ternary;
            hdr.data.b2: ternary;
        }
        default_action = NoAction_0();
    }
    @name("test2") table test2() {
        actions = {
            @default_only NoAction_4();
        }
        key = {
            hdr.data.f1: ternary;
            hdr.data.b1: ternary;
            hdr.data.b2: ternary;
        }
        default_action = NoAction_4();
    }
    @name("test3") table test3() {
        actions = {
            @default_only NoAction_5();
        }
        key = {
            hdr.data.f2: ternary;
            hdr.data.b1: ternary;
        }
        default_action = NoAction_5();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
