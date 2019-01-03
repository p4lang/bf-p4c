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
    bit<8>  b8;
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
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".setb2_5") action setb2_0(bit<8> val2, bit<8> val3, bit<8> val4, bit<8> val5, bit<8> val6) {
        hdr.data.b2 = val2;
        hdr.data.b3 = val3;
        hdr.data.b4 = val4;
        hdr.data.b5 = val5;
        hdr.data.b6 = val6;
    }
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_2() {
    }
    @name(".setb1") action setb1(bit<8> val1, bit<9> port) {
        hdr.data.b1 = val1;
        standard_metadata.egress_spec = port;
    }
    @name(".test1") table test1_0 {
        actions = {
            setb2_0();
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
            hdr.data.f2: exact @name("data.f2") ;
            hdr.data.f3: exact @name("data.f3") ;
            hdr.data.b7: exact @name("data.b7") ;
        }
        default_action = NoAction_0();
    }
    @name(".test2") table test2_0 {
        actions = {
            setb1();
            noop_2();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction_3();
    }
    apply {
        if (hdr.data.f4 == 32w0x1) 
            test1_0.apply();
        test2_0.apply();
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

