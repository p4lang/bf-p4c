#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  c1;
    bit<8>  c2;
    bit<8>  c3;
    bit<8>  c4;
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
    @name(".NoAction") action NoAction_3() {
    }
    @name(".cnt") direct_counter(CounterType.packets) cnt_0;
    @name(".cnt2") direct_counter(CounterType.bytes) cnt2_0;
    @name(".cnt3") direct_counter(CounterType.packets) cnt3_0;
    @name(".cnt4") direct_counter(CounterType.bytes) cnt4_0;
    @name(".c1_2") action c1_0(bit<8> val1, bit<8> val2) {
        cnt_0.count();
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
    }
    @name(".test1") table test1_0 {
        actions = {
            c1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        counters = cnt_0;
        default_action = NoAction_0();
    }
    @name(".c3_4") action c3_0(bit<8> val3, bit<8> val4, bit<9> port) {
        cnt3_0.count();
        hdr.data.c3 = val3;
        hdr.data.c4 = val4;
        standard_metadata.egress_spec = port;
    }
    @name(".test2") table test2_0 {
        actions = {
            c3_0();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 1024;
        counters = cnt3_0;
        default_action = NoAction_3();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
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

