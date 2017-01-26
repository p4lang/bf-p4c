#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
    bit<8> b4;
    bit<8> b5;
    bit<8> b6;
    bit<8> b7;
    bit<8> b8;
    bit<8> b9;
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
    @name("noop") action noop_0() {
    }
    @name("test1") table test1_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b1: exact;
        }
        default_action = NoAction();
    }
    @name("test2") table test2_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b2: exact;
        }
        default_action = NoAction();
    }
    @name("test3") table test3_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b3: exact;
        }
        default_action = NoAction();
    }
    @name("test4") table test4_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b4: exact;
        }
        default_action = NoAction();
    }
    @name("test5") table test5_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b5: exact;
        }
        default_action = NoAction();
    }
    @name("test6") table test6_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b6: exact;
        }
        default_action = NoAction();
    }
    @name("test7") table test7_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b7: exact;
        }
        default_action = NoAction();
    }
    @name("test8") table test8_0() {
        actions = {
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b8: exact;
            hdr.data.b9: exact;
        }
        default_action = NoAction();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
        test4_0.apply();
        test5_0.apply();
        test6_0.apply();
        test7_0.apply();
        test8_0.apply();
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
