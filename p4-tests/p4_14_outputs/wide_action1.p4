#include <core.p4>
#include <v1model.p4>

header h_t {
    bit<32> read;
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
}

struct metadata {
}

struct headers {
    @name(".h") 
    h_t h;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.h);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_wide_action") action set_wide_action(bit<32> param1, bit<32> param2, bit<32> param3, bit<32> param4, bit<32> param5, bit<32> param6, bit<9> port) {
        hdr.h.f1 = param1;
        hdr.h.f2 = param2;
        hdr.h.f3 = param3;
        hdr.h.f4 = param4;
        hdr.h.f5 = param5;
        hdr.h.f6 = param6;
        standard_metadata.egress_spec = port;
    }
    @name(".t") table t {
        actions = {
            set_wide_action;
        }
        key = {
            hdr.h.read: ternary;
        }
        size = 7168;
    }
    apply {
        t.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.h);
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

