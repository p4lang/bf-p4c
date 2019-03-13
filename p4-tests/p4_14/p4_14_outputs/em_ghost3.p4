#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<2> x1;
    bit<4> n1;
    bit<2> x2;
    bit<2> x3;
    bit<4> n2;
    bit<2> x4;
    bit<2> x5;
    bit<4> n3;
    bit<2> x6;
    bit<8> b1;
    bit<8> b2;
    bit<8> b_out;
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
    @name(".setb_out") action setb_out(bit<8> val, bit<9> port) {
        hdr.data.b_out = val;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            setb_out;
            noop;
        }
        key = {
            hdr.data.n1: exact;
            hdr.data.n2: exact;
            hdr.data.n3: exact;
            hdr.data.b1: exact;
            hdr.data.b2: exact;
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

