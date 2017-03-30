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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_8() {
    }
    @name("NoAction") action NoAction_9() {
    }
    @name("NoAction") action NoAction_10() {
    }
    @name("NoAction") action NoAction_11() {
    }
    @name("NoAction") action NoAction_12() {
    }
    @name("NoAction") action NoAction_13() {
    }
    @name(".noop") action noop_0() {
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
    @name("test1") table test1 {
        actions = {
            noop_0();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.f2: exact @name("hdr.data.f2") ;
            hdr.data.w1: exact @name("hdr.data.w1") ;
            hdr.data.w2: exact @name("hdr.data.w2") ;
        }
        default_action = NoAction_0();
    }
    @name("test2") table test2 {
        actions = {
            noop_7();
            @default_only NoAction_8();
        }
        key = {
            hdr.data.f3: exact @name("hdr.data.f3") ;
            hdr.data.f4: exact @name("hdr.data.f4") ;
            hdr.data.w3: exact @name("hdr.data.w3") ;
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        default_action = NoAction_8();
    }
    @name("test3") table test3 {
        actions = {
            noop_8();
            @default_only NoAction_9();
        }
        key = {
            hdr.data.f5: exact @name("hdr.data.f5") ;
            hdr.data.w4: exact @name("hdr.data.w4") ;
            hdr.data.w5: exact @name("hdr.data.w5") ;
            hdr.data.b2: exact @name("hdr.data.b2") ;
            hdr.data.b3: exact @name("hdr.data.b3") ;
        }
        default_action = NoAction_9();
    }
    @name("test4") table test4 {
        actions = {
            noop_9();
            @default_only NoAction_10();
        }
        key = {
            hdr.data.f6: exact @name("hdr.data.f6") ;
            hdr.data.f7: exact @name("hdr.data.f7") ;
        }
        default_action = NoAction_10();
    }
    @name("test5") table test5 {
        actions = {
            noop_10();
            @default_only NoAction_11();
        }
        key = {
            hdr.data.w6: exact @name("hdr.data.w6") ;
            hdr.data.w7: exact @name("hdr.data.w7") ;
            hdr.data.b6: exact @name("hdr.data.b6") ;
        }
        default_action = NoAction_11();
    }
    @name("test6") table test6 {
        actions = {
            noop_11();
            @default_only NoAction_12();
        }
        key = {
            hdr.data.w8: exact @name("hdr.data.w8") ;
            hdr.data.b7: exact @name("hdr.data.b7") ;
        }
        default_action = NoAction_12();
    }
    @name("test7") table test7 {
        actions = {
            noop_12();
            @default_only NoAction_13();
        }
        key = {
            hdr.data.f8: exact @name("hdr.data.f8") ;
        }
        default_action = NoAction_13();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
        test7.apply();
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
