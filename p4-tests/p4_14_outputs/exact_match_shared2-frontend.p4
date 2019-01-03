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
    bit<32> f8;
    bit<16> w1;
    bit<16> w2;
    bit<16> w3;
    bit<16> w4;
    bit<16> w5;
    bit<16> w6;
    bit<16> w7;
    bit<16> w8;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<8>  b6;
    bit<8>  b7;
    bit<8>  b8;
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
    @name(".NoAction") action NoAction_8() {
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
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_7() {
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
    @name(".test1") table test1_0 {
        actions = {
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.f2: exact @name("data.f2") ;
            hdr.data.w1: exact @name("data.w1") ;
            hdr.data.w2: exact @name("data.w2") ;
        }
        default_action = NoAction_0();
    }
    @name(".test2") table test2_0 {
        actions = {
            noop_7();
            @defaultonly NoAction_8();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
            hdr.data.f4: exact @name("data.f4") ;
            hdr.data.w3: exact @name("data.w3") ;
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = NoAction_8();
    }
    @name(".test3") table test3_0 {
        actions = {
            noop_8();
            @defaultonly NoAction_9();
        }
        key = {
            hdr.data.f5: exact @name("data.f5") ;
            hdr.data.w4: exact @name("data.w4") ;
            hdr.data.w5: exact @name("data.w5") ;
            hdr.data.b2: exact @name("data.b2") ;
            hdr.data.b3: exact @name("data.b3") ;
        }
        default_action = NoAction_9();
    }
    @name(".test4") table test4_0 {
        actions = {
            noop_9();
            @defaultonly NoAction_10();
        }
        key = {
            hdr.data.f6: exact @name("data.f6") ;
            hdr.data.f7: exact @name("data.f7") ;
        }
        default_action = NoAction_10();
    }
    @name(".test5") table test5_0 {
        actions = {
            noop_10();
            @defaultonly NoAction_11();
        }
        key = {
            hdr.data.w6: exact @name("data.w6") ;
            hdr.data.w7: exact @name("data.w7") ;
            hdr.data.b6: exact @name("data.b6") ;
        }
        default_action = NoAction_11();
    }
    @name(".test6") table test6_0 {
        actions = {
            noop_11();
            @defaultonly NoAction_12();
        }
        key = {
            hdr.data.w8: exact @name("data.w8") ;
            hdr.data.b7: exact @name("data.b7") ;
        }
        default_action = NoAction_12();
    }
    @name(".test7") table test7_0 {
        actions = {
            noop_12();
            @defaultonly NoAction_13();
        }
        key = {
            hdr.data.f8: exact @name("data.f8") ;
        }
        default_action = NoAction_13();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
        test4_0.apply();
        test5_0.apply();
        test6_0.apply();
        test7_0.apply();
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

