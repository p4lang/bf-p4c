#include <core.p4>
#include <v1model.p4>

header one_byte_t {
    bit<8> a;
}

struct metadata {
}

struct headers {
    @name(".one") 
    one_byte_t one;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".oneb") state oneb {
        packet.extract(hdr.one);
        transition accept;
    }
    @name(".start") state start {
        transition oneb;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_0() {
        hdr.one.a = hdr.one.a + 8w1;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            action_0;
        }
        key = {
            hdr.one.a: ternary;
        }
        size = 512;
    }
    apply {
        table_i0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.one);
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

