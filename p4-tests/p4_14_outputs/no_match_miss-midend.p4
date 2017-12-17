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
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port_act") action set_port_act_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop_0() {
    }
    @name(".a1") action a1_0() {
        hdr.data.f1 = hdr.data.f2;
    }
    @name(".a2") action a2_0() {
        hdr.data.b1 = hdr.data.b2;
    }
    @name(".a3") action a3_0(bit<16> param) {
        hdr.data.h1 = param;
    }
    @name(".a4") action a4_0(bit<32> param1, bit<32> param2) {
        hdr.data.f3 = param1;
        hdr.data.f4 = param2;
    }
    @name(".set_port") table set_port {
        actions = {
            set_port_act_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_0();
    }
    @name(".t1") table t1 {
        actions = {
            a1_0();
            a2_0();
        }
        default_action = a1_0();
    }
    @name(".t2") table t2 {
        actions = {
            a3_0();
        }
        default_action = a3_0(16w0x6789);
    }
    @name(".t3") table t3 {
        actions = {
            a4_0();
        }
        default_action = a4_0(32w0x12345678, 32w0x76543210);
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

