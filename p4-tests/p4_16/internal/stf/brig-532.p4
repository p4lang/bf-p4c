#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<4> x1;
    bit<4> x2;
}
struct metadata { }
struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
        standard_metadata.egress_spec = 4;
        if (hdr.data.x2 == 0) {
            hdr.data.f2 = hdr.data.f1;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) { apply { } }
control DeparserImpl(packet_out packet, in headers hdr) { apply { packet.emit(hdr.data); } }
control verifyChecksum(inout headers hdr, inout metadata meta) { apply { } }
control computeChecksum(inout headers hdr, inout metadata meta) { apply { } }
V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
