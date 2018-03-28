#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<4>  x1;
    bit<4>  x2;
}

struct metadata {
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @hidden action act() {
        hdr.data.f2 = hdr.data.f1;
    }
    @hidden action act_0() {
        standard_metadata.egress_spec = 9w3;
    }
    @hidden table tbl_act {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    @hidden table tbl_act_0 {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
        if (hdr.data.x2 == 4w0) 
            tbl_act_0.apply();
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

