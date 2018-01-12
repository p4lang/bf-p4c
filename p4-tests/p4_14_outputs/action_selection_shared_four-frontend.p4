#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_5() {
    }
    @name("NoAction") action NoAction_6() {
    }
    @name("NoAction") action NoAction_7() {
    }
    @name(".setb1") action setb1_0(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb1") action setb1_4(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb1") action setb1_5(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb1") action setb1_6(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb2") action setb2_0(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb2") action setb2_4(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb2") action setb2_5(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb2") action setb2_6(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb3") action setb3_0(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb3") action setb3_4(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb3") action setb3_5(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb3") action setb3_6(bit<8> val3) {
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
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 10000;
        implementation = set_b1_3;
        default_action = NoAction_0();
    }
    @name(".test2") table test2 {
        actions = {
            setb1_4();
            setb2_4();
            setb3_4();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 5000;
        implementation = set_b1_3;
        default_action = NoAction_5();
    }
    @name(".test3") table test3 {
        actions = {
            setb1_5();
            setb2_5();
            setb3_5();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 2000;
        implementation = set_b1_3;
        default_action = NoAction_6();
    }
    @name(".test4") table test4 {
        actions = {
            setb1_6();
            setb2_6();
            setb3_6();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.data.f4: exact @name("data.f4") ;
            hdr.data.h1: selector @name("data.h1") ;
            hdr.data.h2: selector @name("data.h2") ;
            hdr.data.h3: selector @name("data.h3") ;
        }
        size = 1024;
        implementation = set_b1_3;
        default_action = NoAction_7();
    }
    apply {
        if (hdr.data.b4 == 8w0 || hdr.data.b4 == 8w2) 
            if (hdr.data.b4 == 8w0) 
                test1.apply();
            else 
                test2.apply();
        else 
            if (hdr.data.b4 == 8w3) 
                test3.apply();
            else 
                test4.apply();
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

