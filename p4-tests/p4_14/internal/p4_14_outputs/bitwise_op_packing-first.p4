#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f0;
    bit<8>  f1;
    bit<8>  f2;
    bit<7>  pad1;
    bit<1>  f3;
    bit<7>  pad2;
    bit<1>  f4;
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
    @name(".and_action") action and_action() {
        hdr.data.f4 = hdr.data.f3 & hdr.data.f4;
        hdr.data.pad2 = hdr.data.pad1 & hdr.data.pad2;
    }
    @name(".noop") action noop() {
    }
    @name(".and_action") table and_action_0 {
        actions = {
            and_action();
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
    }
    apply {
        and_action_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
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

