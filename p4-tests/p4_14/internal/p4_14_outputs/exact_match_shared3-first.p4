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
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
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
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
            hdr.data.f4: exact @name("data.f4") ;
            hdr.data.f5: exact @name("data.f5") ;
        }
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f6 : exact @name("data.f6") ;
            hdr.data.f12: exact @name("data.f12") ;
            hdr.data.f13: exact @name("data.f13") ;
            hdr.data.f14: exact @name("data.f14") ;
        }
        default_action = NoAction();
    }
    @name(".test4") table test4 {
        actions = {
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f6 : exact @name("data.f6") ;
            hdr.data.f7 : exact @name("data.f7") ;
            hdr.data.f8 : exact @name("data.f8") ;
            hdr.data.f9 : exact @name("data.f9") ;
            hdr.data.f10: exact @name("data.f10") ;
            hdr.data.f11: exact @name("data.f11") ;
        }
        default_action = NoAction();
    }
    @name(".test5") table test5 {
        actions = {
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f12: exact @name("data.f12") ;
            hdr.data.f13: exact @name("data.f13") ;
            hdr.data.f14: exact @name("data.f14") ;
            hdr.data.f7 : exact @name("data.f7") ;
            hdr.data.f8 : exact @name("data.f8") ;
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

