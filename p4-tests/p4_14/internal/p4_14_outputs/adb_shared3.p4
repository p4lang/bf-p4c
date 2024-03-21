#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32>  read;
    bit<128> x1;
    bit<128> x2;
    bit<32>  extra;
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
    @name(".bigwrite") action bigwrite(bit<128> big1, bit<128> big2, bit<32> ex_param) {
        hdr.data.x1 = big1;
        hdr.data.x2 = big2;
        hdr.data.extra = ex_param;
    }
    @name(".test1") table test1 {
        actions = {
            bigwrite;
        }
        key = {
            hdr.data.read: exact;
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

