#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<4>  n1;
    bit<4>  n2;
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
    @name(".setport") action setport_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".set_nibbles") action set_nibbles_0(bit<4> param1, bit<4> param2) {
        hdr.data.n1 = param1;
        hdr.data.n2 = param2;
    }
    @name(".setting_port") table setting_port_0 {
        actions = {
            setport_0();
        }
        default_action = setport_0(9w1);
    }
    @name(".test1") table test1_0 {
        actions = {
            set_nibbles_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction();
    }
    apply {
        test1_0.apply();
        setting_port_0.apply();
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
