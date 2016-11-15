#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> c1;
    bit<16> c2;
    bit<16> c3;
    bit<16> c4;
    bit<16> c5;
    bit<16> c6;
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
    @name("c1_3") action c1_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
        hdr.data.c3 = val3;
    }
    @name("c4_6") action c4_0(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        hdr.data.c4 = val4;
        hdr.data.c5 = val5;
        hdr.data.c6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name("test1") table test1_0() {
        actions = {
            c1_0();
            NoAction();
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 32768;
        default_action = NoAction();
        @name("cnt") counters = direct_counter(CounterType.packets);
    }
    @name("test2") table test2_0() {
        actions = {
            c4_0();
            NoAction();
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 10000;
        default_action = NoAction();
        @name("cnt2") counters = direct_counter(CounterType.packets);
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
