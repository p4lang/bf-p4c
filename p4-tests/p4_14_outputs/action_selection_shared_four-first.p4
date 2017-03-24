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
    @name("setb1") action setb1(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name("setb2") action setb2(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name("setb3") action setb3(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name("test1") table test1 {
        actions = {
            setb1();
            setb2();
            setb3();
            @default_only NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 10000;
        default_action = NoAction();
        @name("set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
    }
    @name("test2") table test2 {
        actions = {
            setb1();
            setb2();
            setb3();
            @default_only NoAction();
        }
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 5000;
        default_action = NoAction();
        @name("set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
    }
    @name("test3") table test3 {
        actions = {
            setb1();
            setb2();
            setb3();
            @default_only NoAction();
        }
        key = {
            hdr.data.f3: exact @name("hdr.data.f3") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 2000;
        default_action = NoAction();
        @name("set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
    }
    @name("test4") table test4 {
        actions = {
            setb1();
            setb2();
            setb3();
            @default_only NoAction();
        }
        key = {
            hdr.data.f4: exact @name("hdr.data.f4") ;
            hdr.data.h1: selector @name("hdr.data.h1") ;
            hdr.data.h2: selector @name("hdr.data.h2") ;
            hdr.data.h3: selector @name("hdr.data.h3") ;
        }
        size = 1024;
        default_action = NoAction();
        @name("set_b1_3") @mode("fair") implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w14);
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
