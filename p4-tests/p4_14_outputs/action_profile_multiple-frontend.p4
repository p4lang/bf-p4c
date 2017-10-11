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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setb1") action setb1_0(bit<8> val1) {
        hdr.data.b1 = val1;
    }
    @name(".setb2") action setb2_0(bit<8> val2) {
        hdr.data.b2 = val2;
    }
    @name(".setb3") action setb3_0(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".setb5") action setb5_0(bit<8> val5) {
        hdr.data.b5 = val5;
    }
    @name(".setb6") action setb6_0(bit<8> val6) {
        hdr.data.b6 = val6;
    }
    @name(".setb7") action setb7_0(bit<8> val7) {
        hdr.data.b7 = val7;
    }
    @name(".test1") table test1_0 {
        actions = {
            setb1_0();
            setb2_0();
            setb3_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 10000;
        @name(".set_b1_3") implementation = action_profile(32w1024);
        default_action = NoAction();
    }
    @name(".test2") table test2_0 {
        actions = {
            setb1_0();
            setb2_0();
            setb3_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 5000;
        @name(".set_b1_3") implementation = action_profile(32w1024);
        default_action = NoAction();
    }
    @name(".test3") table test3_0 {
        actions = {
            setb5_0();
            setb6_0();
            setb7_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f3: exact @name("data.f3") ;
        }
        size = 5000;
        @name(".set_b5_7") implementation = action_profile(32w2048);
        default_action = NoAction();
    }
    @name(".test4") table test4_0 {
        actions = {
            setb5_0();
            setb6_0();
            setb7_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f4: exact @name("data.f4") ;
        }
        size = 10000;
        @name(".set_b5_7") implementation = action_profile(32w2048);
        default_action = NoAction();
    }
    apply {
        if (hdr.data.b4 == 8w0) {
            test1_0.apply();
            test3_0.apply();
        }
        else {
            test2_0.apply();
            test4_0.apply();
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
