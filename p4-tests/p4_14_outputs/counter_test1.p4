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
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("cnt") direct_counter(CounterType.packets) cnt;
    @name("cnt2") direct_counter(CounterType.packets) cnt2;
    @name(".c1_3") action c1_3(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.c1 = (bit<16>)val1;
        hdr.data.c2 = (bit<16>)val2;
        hdr.data.c3 = (bit<16>)val3;
    }
    @name(".c4_6") action c4_6(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        hdr.data.c4 = (bit<16>)val4;
        hdr.data.c5 = (bit<16>)val5;
        hdr.data.c6 = (bit<16>)val6;
        standard_metadata.egress_spec = (bit<9>)port;
    }
    @name(".c1_3") action c1_3_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        cnt.count();
        hdr.data.c1 = (bit<16>)val1;
        hdr.data.c2 = (bit<16>)val2;
        hdr.data.c3 = (bit<16>)val3;
    }
    @name("test1") table test1 {
        actions = {
            c1_3_0;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 32768;
        @name("cnt") counters = direct_counter(CounterType.packets);
    }
    @name(".c4_6") action c4_6_0(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        cnt2.count();
        hdr.data.c4 = (bit<16>)val4;
        hdr.data.c5 = (bit<16>)val5;
        hdr.data.c6 = (bit<16>)val6;
        standard_metadata.egress_spec = (bit<9>)port;
    }
    @name("test2") table test2 {
        actions = {
            c4_6_0;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 10000;
        @name("cnt2") counters = direct_counter(CounterType.packets);
    }
    apply {
        test1.apply();
        test2.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
