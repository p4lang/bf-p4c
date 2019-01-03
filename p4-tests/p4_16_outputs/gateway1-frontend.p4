#include <core.p4>
#include <v1model.p4>

struct metadata {
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
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
    @name("ingress.setb1") action setb1(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.noop") action noop() {
    }
    @name("ingress.test") table test_0 {
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
        }
        actions = {
            setb1();
            noop();
        }
        default_action = setb1(8w0xaa);
    }
    apply {
        standard_metadata.egress_spec = 9w2;
        if (hdr.data.f2[27:20] == 8w0 && hdr.data.f2[11:4] == 8w1) 
            test_0.apply();
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

