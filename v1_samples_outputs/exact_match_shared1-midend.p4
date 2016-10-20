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
    @name("NoAction_1") action NoAction() {
    }
    @name("NoAction_2") action NoAction_0() {
    }
    @name("NoAction_3") action NoAction_9() {
    }
    @name("NoAction_4") action NoAction_10() {
    }
    @name("NoAction_5") action NoAction_11() {
    }
    @name("NoAction_6") action NoAction_12() {
    }
    @name("NoAction_7") action NoAction_13() {
    }
    @name("NoAction_8") action NoAction_14() {
    }
    @name("noop") action noop_0() {
    }
    @name("noop") action noop_8() {
    }
    @name("noop") action noop_9() {
    }
    @name("noop") action noop_10() {
    }
    @name("noop") action noop_11() {
    }
    @name("noop") action noop_12() {
    }
    @name("noop") action noop_13() {
    }
    @name("noop") action noop_14() {
    }
    @name("test1") table test1() {
        actions = {
            noop_0();
            NoAction();
        }
        key = {
            hdr.data.b1: exact;
        }
        default_action = NoAction();
    }
    @name("test2") table test2() {
        actions = {
            noop_8();
            NoAction_0();
        }
        key = {
            hdr.data.b2: exact;
        }
        default_action = NoAction_0();
    }
    @name("test3") table test3() {
        actions = {
            noop_9();
            NoAction_9();
        }
        key = {
            hdr.data.b3: exact;
        }
        default_action = NoAction_9();
    }
    @name("test4") table test4() {
        actions = {
            noop_10();
            NoAction_10();
        }
        key = {
            hdr.data.b4: exact;
        }
        default_action = NoAction_10();
    }
    @name("test5") table test5() {
        actions = {
            noop_11();
            NoAction_11();
        }
        key = {
            hdr.data.b5: exact;
        }
        default_action = NoAction_11();
    }
    @name("test6") table test6() {
        actions = {
            noop_12();
            NoAction_12();
        }
        key = {
            hdr.data.b6: exact;
        }
        default_action = NoAction_12();
    }
    @name("test7") table test7() {
        actions = {
            noop_13();
            NoAction_13();
        }
        key = {
            hdr.data.b7: exact;
        }
        default_action = NoAction_13();
    }
    @name("test8") table test8() {
        actions = {
            noop_14();
            NoAction_14();
        }
        key = {
            hdr.data.b8: exact;
            hdr.data.b9: exact;
        }
        default_action = NoAction_14();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
        test7.apply();
        test8.apply();
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
