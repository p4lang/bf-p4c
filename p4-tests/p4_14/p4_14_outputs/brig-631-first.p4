#include <core.p4>
#include <v1model.p4>

header h_t {
    bit<32> f;
}

struct metadata {
}

struct headers {
    @name(".h") 
    h_t h;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_h") state parse_h {
        packet.extract<h_t>(hdr.h);
        transition accept;
    }
    @name(".start") state start {
        transition parse_h;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a") action a() {
        hdr.h.f = hdr.h.f + 32w4294967286;
    }
    @name(".t") table t {
        actions = {
            a();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.h.isValid()) 
            t.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<h_t>(hdr.h);
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

