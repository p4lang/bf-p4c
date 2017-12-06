#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> r1;
    bit<32> r2;
    bit<32> r3;
    bit<32> r4;
    bit<32> r5;
    bit<32> r6;
    bit<32> r7;
    bit<32> r8;
    bit<32> r9;
    bit<32> r10;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
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
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

@name(".set_b1_3") @mode("fair") action_selector(HashAlgorithm.crc16, 32w1024, 32w14) set_b1_3;

@name(".set_r1_10") @mode("fair") action_selector(HashAlgorithm.crc16, 32w18000, 32w14) set_r1_10;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setr1_5") action setr1_5(bit<32> val1, bit<32> val2, bit<32> val3, bit<32> val4, bit<32> val5) {
        hdr.data.r1 = val1;
        hdr.data.r2 = val2;
        hdr.data.r3 = val3;
        hdr.data.r4 = val4;
        hdr.data.r5 = val5;
    }
    @name(".setr6_10") action setr6_10(bit<32> val6, bit<32> val7, bit<32> val8, bit<32> val9, bit<32> val10) {
        hdr.data.r6 = val6;
        hdr.data.r7 = val7;
        hdr.data.r8 = val8;
        hdr.data.r9 = val9;
        hdr.data.r10 = val10;
    }
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
            setr1_5();
            setr6_10();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 10000;
        implementation = set_r1_10;
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            setb1();
            setb2();
            setb3();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 1024;
        implementation = set_b1_3;
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

