#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> c1;
    bit<16> c2;
    bit<16> c3;
    bit<16> c4;
    bit<16> c5;
    bit<16> c6;
    bit<16> c7;
    bit<16> c8;
    bit<16> c9;
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
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".cnt") direct_counter(CounterType.packets) cnt_0;
    @name(".cnt2") direct_counter(CounterType.packets) cnt2_0;
    @name(".cnt3") direct_counter(CounterType.packets) cnt3_0;
    @name(".c1_3") action c1_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        cnt_0.count();
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
        hdr.data.c3 = val3;
    }
    @name(".test1") table test1_0 {
        actions = {
            c1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 16384;
        counters = cnt_0;
        default_action = NoAction_0();
    }
    @name(".c4_6") action c4_0(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        cnt2_0.count();
        hdr.data.c4 = val4;
        hdr.data.c5 = val5;
        hdr.data.c6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name(".test2") table test2_0 {
        actions = {
            c4_0();
            @defaultonly NoAction_4();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 16384;
        counters = cnt2_0;
        default_action = NoAction_4();
    }
    @name(".c7_9") action c7_0(bit<16> val7, bit<16> val8, bit<16> val9) {
        cnt3_0.count();
        hdr.data.c7 = val7;
        hdr.data.c8 = val8;
        hdr.data.c9 = val9;
    }
    @name(".test3") table test3_0 {
        actions = {
            c7_0();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        size = 1024;
        counters = cnt3_0;
        default_action = NoAction_5();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
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

