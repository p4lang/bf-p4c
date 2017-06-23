#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
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
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_3() {
    }
    @name(".setb1") action setb1_0(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb1") action setb1_2(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb2") action setb2_0(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb2") action setb2_2(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb3") action setb3_0(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb3") action setb3_2(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".test1") table test1 {
        actions = {
            setb1_0();
            setb2_0();
            setb3_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 10000;
        @name(".set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
        default_action = NoAction_0();
    }
    @name(".test2") table test2 {
        actions = {
            setb1_2();
            setb2_2();
            setb3_2();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 5000;
        @name(".set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
        default_action = NoAction_3();
    }
    apply {
        if (hdr.data.b4 == 8w0) 
            test1.apply();
        else 
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
