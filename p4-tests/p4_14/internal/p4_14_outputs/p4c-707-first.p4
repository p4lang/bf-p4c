#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> r1;
    bit<32> w1;
    bit<32> w2;
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

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setw2") action setw2(bit<32> param1) {
        hdr.data.w2 = param1;
    }
    @name(".noop") action noop() {
    }
    @stage(2) @name(".e1") table e1 {
        actions = {
            setw2();
            noop();
        }
        key = {
            hdr.data.r1: exact @name("data.r1") ;
        }
        default_action = noop();
    }
    apply {
        e1.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setw1") action setw1(bit<32> param1, bit<9> port) {
        hdr.data.w1 = param1;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @stage(1) @name(".i1") table i1 {
        actions = {
            setw1();
            noop();
        }
        key = {
            hdr.data.r1: exact @name("data.r1") ;
        }
        default_action = noop();
    }
    apply {
        i1.apply();
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

