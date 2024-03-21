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
    @name(".cnt") direct_counter(CounterType.packets) cnt;
    @name(".c1_2") action c1_2(bit<8> val1, bit<8> val2) {
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
    }
    @name(".c3_4") action c3_4(bit<8> val3, bit<8> val4, bit<9> port) {
        hdr.data.c3 = val3;
        hdr.data.c4 = val4;
        standard_metadata.egress_spec = port;
    }
    @name(".c1_2") action c1_2_0(bit<8> val1, bit<8> val2) {
        cnt.count();
        hdr.data.c1 = val1;
        hdr.data.c2 = val2;
    }
    @name(".test1") table test1 {
        actions = {
            c1_2_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        counters = cnt;
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            c3_4();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 1024;
        default_action = NoAction();
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

