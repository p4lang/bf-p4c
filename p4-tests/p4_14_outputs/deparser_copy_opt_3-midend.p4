#include <core.p4>
#include <v1model.p4>

@command_line("--decaf") header data_t {
    bit<8>  m;
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        standard_metadata.egress_spec = 9w0x2;
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> temp_3;
    bit<32> temp_4;
    bit<32> temp_5;
    bit<32> temp_6;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".a1") action a1() {
        temp_3 = hdr.data.a;
        hdr.data.a = hdr.data.b;
        hdr.data.b = temp_3;
    }
    @name(".a2") action a2() {
        temp_4 = hdr.data.c;
        hdr.data.c = hdr.data.d;
        hdr.data.d = temp_4;
    }
    @name(".a3") action a3() {
        temp_5 = hdr.data.a;
        hdr.data.a = hdr.data.c;
        hdr.data.c = temp_5;
    }
    @name(".a4") action a4() {
        temp_6 = hdr.data.b;
        hdr.data.b = hdr.data.d;
        hdr.data.d = temp_6;
    }
    @name(".paws") table paws_0 {
        actions = {
            a1();
            a2();
            a3();
            a4();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.m: exact @name("data.m") ;
        }
        default_action = NoAction_0();
    }
    apply {
        paws_0.apply();
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

