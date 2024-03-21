#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> a;
    bit<16> b;
    bit<16> c;
    bit<16> d;
    bit<32> e;
    bit<32> f;
    bit<32> g;
    bit<32> h;
    bit<8>  i;
    bit<8>  j;
    bit<8>  k;
    bit<8>  l;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
    bit<16> blah0;
    bit<8>  blah1;
    bit<8>  blah2;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_0(bit<16> blah1, bit<16> blah2, bit<16> blah3) {
        meta.meta.a = blah1;
        meta.meta.b = blah2;
        meta.meta.c = blah3;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_1") action action_1() {
        meta.meta.e = 32w7;
        meta.meta.f = 32w8;
        meta.meta.g = 32w2097151;
        meta.meta.h = 32w4294967295;
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0;
            do_nothing;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 1024;
    }
    @immediate(0) @name(".table_1") table table_1 {
        actions = {
            action_1;
            do_nothing;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 1024;
    }
    apply {
        table_0.apply();
        table_1.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
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

