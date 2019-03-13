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
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".NoAction") action NoAction_12() {
    }
    @name(".NoAction") action NoAction_13() {
    }
    @name(".NoAction") action NoAction_14() {
    }
    @name(".NoAction") action NoAction_15() {
    }
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_8() {
    }
    @name(".noop") action noop_9() {
    }
    @name(".noop") action noop_10() {
    }
    @name(".noop") action noop_11() {
    }
    @name(".noop") action noop_12() {
    }
    @name(".noop") action noop_13() {
    }
    @name(".noop") action noop_14() {
    }
    @name(".test1") table test1_0 {
        actions = {
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = NoAction_0();
    }
    @name(".test2") table test2_0 {
        actions = {
            noop_8();
            @defaultonly NoAction_9();
        }
        key = {
            hdr.data.b2: exact @name("data.b2") ;
        }
        default_action = NoAction_9();
    }
    @name(".test3") table test3_0 {
        actions = {
            noop_9();
            @defaultonly NoAction_10();
        }
        key = {
            hdr.data.b3: exact @name("data.b3") ;
        }
        default_action = NoAction_10();
    }
    @name(".test4") table test4_0 {
        actions = {
            noop_10();
            @defaultonly NoAction_11();
        }
        key = {
            hdr.data.b4: exact @name("data.b4") ;
        }
        default_action = NoAction_11();
    }
    @name(".test5") table test5_0 {
        actions = {
            noop_11();
            @defaultonly NoAction_12();
        }
        key = {
            hdr.data.b5: exact @name("data.b5") ;
        }
        default_action = NoAction_12();
    }
    @name(".test6") table test6_0 {
        actions = {
            noop_12();
            @defaultonly NoAction_13();
        }
        key = {
            hdr.data.b6: exact @name("data.b6") ;
        }
        default_action = NoAction_13();
    }
    @name(".test7") table test7_0 {
        actions = {
            noop_13();
            @defaultonly NoAction_14();
        }
        key = {
            hdr.data.b7: exact @name("data.b7") ;
        }
        default_action = NoAction_14();
    }
    @name(".test8") table test8_0 {
        actions = {
            noop_14();
            @defaultonly NoAction_15();
        }
        key = {
            hdr.data.b8: exact @name("data.b8") ;
            hdr.data.b9: exact @name("data.b9") ;
        }
        default_action = NoAction_15();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

