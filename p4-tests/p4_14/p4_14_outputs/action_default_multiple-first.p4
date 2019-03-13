#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
    bit<8> b4;
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
    @name(".b1_act") action b1_act(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name(".b4_act") action b4_act(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name(".set_port") action set_port(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".b2_act") action b2_act(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name(".b3_act") action b3_act(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name(".first") table first {
        actions = {
            b1_act();
        }
        default_action = b1_act(8w1);
    }
    @name(".fourth") table fourth {
        actions = {
            b4_act();
        }
        default_action = b4_act(8w4);
    }
    @name(".port_set") table port_set {
        actions = {
            set_port();
        }
        default_action = set_port(9w5);
    }
    @name(".second") table second {
        actions = {
            b2_act();
        }
        default_action = b2_act(8w2);
    }
    @name(".third") table third {
        actions = {
            b3_act();
        }
        default_action = b3_act(8w3);
    }
    apply {
        first.apply();
        second.apply();
        third.apply();
        fourth.apply();
        port_set.apply();
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

