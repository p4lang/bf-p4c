#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<80> b7;
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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_1") action NoAction() {
    }
    @name("NoAction_2") action NoAction_0() {
    }
    @name("NoAction_3") action NoAction_4() {
    }
    @name("noop") action noop_0() {
    }
    @name("noop") action noop_3() {
    }
    @name("noop") action noop_4() {
    }
    @name("test1") table test1() {
        actions = {
            noop_0();
            NoAction();
        }
        key = {
            hdr.data.b1: ternary;
            hdr.data.b2: ternary;
        }
        default_action = NoAction();
    }
    @name("test2") table test2() {
        actions = {
            noop_3();
            NoAction_0();
        }
        key = {
            hdr.data.b3: ternary;
            hdr.data.b4: ternary;
            hdr.data.b5: ternary;
        }
        default_action = NoAction_0();
    }
    @name("test3") table test3() {
        actions = {
            noop_4();
            NoAction_4();
        }
        key = {
            hdr.data.b1: ternary;
            hdr.data.b2: ternary;
            hdr.data.b3: ternary;
            hdr.data.b4: ternary;
            hdr.data.b7: ternary;
        }
        default_action = NoAction_4();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
