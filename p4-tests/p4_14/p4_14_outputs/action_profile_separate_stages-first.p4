#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
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

@name(".set_b1_3") action_profile(32w1024) set_b1_3;

@name(".set_b5_7") action_profile(32w1024) set_b5_7;

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
    @name(".setb5") action setb5(bit<8> val5) {
        hdr.data.b5 = val5;
    }
    @name(".setb6") action setb6(bit<8> val6) {
        hdr.data.b6 = val6;
    }
    @name(".setb7") action setb7(bit<8> val7) {
        hdr.data.b7 = val7;
    }
    @name(".setf1") action setf1(bit<32> val1) {
        hdr.data.f1 = val1;
    }
    @name(".setf2") action setf2(bit<32> val2) {
        hdr.data.f2 = val2;
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
        }
        size = 10000;
        implementation = set_b1_3;
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            setb5();
            setb6();
            setb7();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 5000;
        implementation = set_b5_7;
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            setb1();
            setb2();
            setb3();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 5000;
        implementation = set_b1_3;
        default_action = NoAction();
    }
    @name(".test4") table test4 {
        actions = {
            setb5();
            setb6();
            setb7();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 10000;
        implementation = set_b5_7;
        default_action = NoAction();
    }
    @name(".test_mid") table test_mid {
        actions = {
            setf1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        default_action = NoAction();
    }
    @name(".test_mid2") table test_mid2 {
        actions = {
            setf2();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f4: exact @name("data.f4") ;
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.data.b4 == 8w0) {
            test1.apply();
            test_mid2.apply();
            test4.apply();
        }
        else {
            test2.apply();
            test_mid.apply();
            test3.apply();
        }
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

