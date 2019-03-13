#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<4>  n1;
    bit<4>  n2;
    bit<32> f2;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_stuff") action set_stuff(bit<4> param1, bit<4> param2, bit<32> param3, bit<9> port) {
        hdr.data.n1 = param1;
        hdr.data.n2 = param2;
        hdr.data.f2 = param3;
        standard_metadata.egress_spec = port;
    }
    @name(".test1") table test1 {
        actions = {
            set_stuff;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        test1.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

