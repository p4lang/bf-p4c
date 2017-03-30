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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_5() {
    }
    @name("NoAction") action NoAction_6() {
    }
    @name("NoAction") action NoAction_7() {
    }
    @name(".noop") action noop_0() {
    }
    @name(".noop") action noop_4() {
    }
    @name(".noop") action noop_5() {
    }
    @name(".noop") action noop_6() {
    }
    @name("test1") table test1 {
        actions = {
            noop_0();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
            hdr.data.f2: ternary @name("hdr.data.f2") ;
            hdr.data.f3: ternary @name("hdr.data.f3") ;
            hdr.data.f4: ternary @name("hdr.data.f4") ;
            hdr.data.f5: ternary @name("hdr.data.f5") ;
            hdr.data.f6: ternary @name("hdr.data.f6") ;
            hdr.data.f7: ternary @name("hdr.data.f7") ;
            hdr.data.b1: ternary @name("hdr.data.b1") ;
            hdr.data.b2: ternary @name("hdr.data.b2") ;
            hdr.data.b3: ternary @name("hdr.data.b3") ;
            hdr.data.b4: ternary @name("hdr.data.b4") ;
        }
        default_action = NoAction_0();
    }
    @name("test2") table test2 {
        actions = {
            noop_4();
            @default_only NoAction_5();
        }
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
        }
        default_action = NoAction_5();
    }
    @name("test3") table test3 {
        actions = {
            noop_5();
            @default_only NoAction_6();
        }
        key = {
            hdr.data.f3: ternary @name("hdr.data.f3") ;
        }
        default_action = NoAction_6();
    }
    @name("test4") table test4 {
        actions = {
            noop_6();
            @default_only NoAction_7();
        }
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
            hdr.data.b3: ternary @name("hdr.data.b3") ;
        }
        default_action = NoAction_7();
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
