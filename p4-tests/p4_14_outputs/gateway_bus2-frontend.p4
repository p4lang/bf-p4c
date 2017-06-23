#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> w1;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
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
    @name(".set_b3") action set_b3_0(bit<8> val3) {
        hdr.data.b3 = val3;
    }
    @name(".noop") action noop_0() {
    }
    @name(".set_port") action set_port_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".test1") table test1_0 {
        actions = {
            set_b3_0();
            noop_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.f2: exact @name("hdr.data.f2") ;
            hdr.data.f3: exact @name("hdr.data.f3") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2_0 {
        actions = {
            set_port_0();
            noop_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.data.b1 == 8w9 && hdr.data.b2 == 8w1) 
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
