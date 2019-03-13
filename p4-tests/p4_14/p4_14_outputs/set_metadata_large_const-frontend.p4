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
        packet.extract<data_t>(hdr.data);
        transition select(hdr.data.h1) {
            16w0xc0de: parse_metadata;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".setf1") action setf1(bit<9> port) {
        hdr.data.f1 = meta.meta.f1;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1_0 {
        actions = {
            setf1();
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.h1: exact @name("data.h1") ;
        }
        default_action = NoAction_0();
    }
    apply {
        test1_0.apply();
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

