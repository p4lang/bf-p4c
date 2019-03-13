#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
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
    bit<8>  b5;
    bit<8>  b6;
    bit<8>  b7;
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

@name(".set_b1_3") @mode("fair") action_selector(HashAlgorithm.crc16, 32w80000, 32w14) set_b1_3;

@name(".set_b4_6") @mode("fair") action_selector(HashAlgorithm.random, 32w1024, 32w14) set_b4_6;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".test3_counter") counter(32w4000, CounterType.packets) test3_counter;
    @name(".setb1") action setb1(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb2") action setb2(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb3") action setb3(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb4") action setb4(bit<8> val4) {
        hdr.data.b4 = val4;
    }
    @name(".setb5") action setb5(bit<8> val5) {
        hdr.data.b5 = val5;
    }
    @name(".setb6") action setb6(bit<8> val6) {
        hdr.data.b6 = val6;
    }
    @name(".my_count") action my_count(bit<32> idx) {
        test3_counter.count(idx);
    }
    @name(".test1") table test1 {
        actions = {
            setb1();
            setb2();
            setb3();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 10000;
        implementation = set_b1_3;
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            setb4();
            setb5();
            setb6();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
            hdr.data.h4: selector @name("data.h4") ;
            hdr.data.h5: selector @name("data.h5") ;
            hdr.data.h6: selector @name("data.h6") ;
        }
        size = 5000;
        implementation = set_b4_6;
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            my_count();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        size = 1024;
        default_action = NoAction();
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

