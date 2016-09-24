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
    bit<32> f9;
    bit<32> f10;
    bit<32> f11;
    bit<32> f12;
    bit<32> f13;
    bit<32> f14;
    bit<32> f15;
    bit<32> f16;
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
    @name("noop") action noop() {
    }
    @name("test1") table test1() {
        actions = {
            noop();
            NoAction();
        }
        key = {
            hdr.data.f1: exact;
            hdr.data.f2: exact;
        }
        default_action = NoAction();
    }
    @name("test2") table test2() {
        actions = {
            noop();
            NoAction();
        }
        key = {
            hdr.data.f3: exact;
            hdr.data.f4: exact;
            hdr.data.f5: exact;
        }
        default_action = NoAction();
    }
    @name("test3") table test3() {
        actions = {
            NoAction();
        }
        key = {
            hdr.data.f6 : exact;
            hdr.data.f12: exact;
            hdr.data.f13: exact;
            hdr.data.f14: exact;
        }
        default_action = NoAction();
    }
    @name("test4") table test4() {
        actions = {
            noop();
            NoAction();
        }
        key = {
            hdr.data.f6 : exact;
            hdr.data.f7 : exact;
            hdr.data.f8 : exact;
            hdr.data.f9 : exact;
            hdr.data.f10: exact;
            hdr.data.f11: exact;
        }
        default_action = NoAction();
    }
    @name("test5") table test5() {
        actions = {
            NoAction();
        }
        key = {
            hdr.data.f12: exact;
            hdr.data.f13: exact;
            hdr.data.f14: exact;
            hdr.data.f7 : exact;
            hdr.data.f8 : exact;
        }
        default_action = NoAction();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
