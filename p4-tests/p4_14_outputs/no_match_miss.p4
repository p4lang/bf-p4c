#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port_act") action set_port_act(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".a1") action a1() {
        hdr.data.f1 = hdr.data.f2;
    }
    @name(".a2") action a2() {
        hdr.data.b1 = hdr.data.b2;
    }
    @name(".a3") action a3(bit<16> param) {
        hdr.data.h1 = param;
    }
    @name(".a4") action a4(bit<32> param1, bit<32> param2) {
        hdr.data.f3 = param1;
        hdr.data.f4 = param2;
    }
    @name(".set_port") table set_port {
        actions = {
            set_port_act;
            noop;
        }
        key = {
            hdr.data.f1: exact;
        }
        default_action = noop();
    }
    @name(".t1") table t1 {
        actions = {
            a1;
            a2;
        }
        default_action = a1();
    }
    @name(".t2") table t2 {
        actions = {
            a3;
        }
        default_action = a3(0x6789);
    }
    @name(".t3") table t3 {
        actions = {
            a4;
        }
        default_action = a4(0x12345678, 0x76543210);
    }
    apply {
        t1.apply();
        t2.apply();
        t3.apply();
        set_port.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

