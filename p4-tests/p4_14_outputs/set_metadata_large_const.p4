#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<64> f1;
}

header data_t {
    bit<16> h1;
    bit<64> f1;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_metadata") state parse_metadata {
        meta.meta.f1 = 64w0xbabedead;
        transition accept;
    }
    @name(".start") state start {
        packet.extract(hdr.data);
        transition select(hdr.data.h1) {
            16w0xc0de: parse_metadata;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setf1") action setf1(bit<9> port) {
        hdr.data.f1 = meta.meta.f1;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            setf1;
            noop;
        }
        key = {
            hdr.data.h1: exact;
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

