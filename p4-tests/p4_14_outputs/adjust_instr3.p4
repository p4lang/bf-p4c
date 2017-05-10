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
    @name("start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = (bit<9>)port;
    }
    @name(".set_nibbles") action set_nibbles(bit<4> param1, bit<4> param2) {
        hdr.data.n1 = (bit<4>)param1;
        hdr.data.n2 = (bit<4>)param2;
    }
    @name("setting_port") table setting_port {
        actions = {
            setport;
        }
        const default_action = setport(1);
    }
    @name("test1") table test1 {
        actions = {
            set_nibbles;
            @default_only NoAction;
        }
        key = {
            hdr.data.f1: exact;
        }
        default_action = NoAction();
    }
    apply {
        test1.apply();
        setting_port.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
