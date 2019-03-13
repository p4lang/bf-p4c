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
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".cnt") direct_counter(CounterType.packets) cnt;
    @name(".cnt2") direct_counter(CounterType.packets) cnt2;
    @name(".cnt3") direct_counter(CounterType.packets) cnt3;
    @name(".c1_3") action c1_3(bit<16> val1, bit<16> val2, bit<16> val3) {
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
        hdr.data.c3 = val3;
    }
    @name(".c4_6") action c4_6(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        hdr.data.c4 = val4;
        hdr.data.c5 = val5;
        hdr.data.c6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name(".c7_9") action c7_9(bit<16> val7, bit<16> val8, bit<16> val9) {
        hdr.data.c7 = val7;
        hdr.data.c8 = val8;
        hdr.data.c9 = val9;
    }
    @name(".c1_3") action c1_3_0(bit<16> val1, bit<16> val2, bit<16> val3) {
        cnt.count();
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
        hdr.data.c3 = val3;
    }
    @name(".test1") table test1 {
        actions = {
            c1_3_0;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 16384;
        counters = cnt;
    }
    @name(".c4_6") action c4_6_0(bit<16> val4, bit<16> val5, bit<16> val6, bit<9> port) {
        cnt2.count();
        hdr.data.c4 = val4;
        hdr.data.c5 = val5;
        hdr.data.c6 = val6;
        standard_metadata.egress_spec = port;
    }
    @name(".test2") table test2 {
        actions = {
            c4_6_0;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 16384;
        counters = cnt2;
    }
    @name(".c7_9") action c7_9_0(bit<16> val7, bit<16> val8, bit<16> val9) {
        cnt3.count();
        hdr.data.c7 = val7;
        hdr.data.c8 = val8;
        hdr.data.c9 = val9;
    }
    @name(".test3") table test3 {
        actions = {
            c7_9_0;
        }
        key = {
            hdr.data.f3: exact;
        }
        size = 1024;
        counters = cnt3;
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

