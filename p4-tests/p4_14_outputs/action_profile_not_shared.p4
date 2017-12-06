#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
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

@name(".set_b1_3") action_profile(32w1024) set_b1_3;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setb1") action setb1(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb2") action setb2(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb3") action setb3(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".test1") table test1 {
        actions = {
            setb1;
            setb2;
            setb3;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 10000;
        implementation = set_b1_3;
    }
    @name(".test2") table test2 {
        actions = {
            setb1;
            setb2;
            setb3;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 5000;
        implementation = set_b1_3;
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

