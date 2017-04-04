#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> a;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    @name("meta") 
    meta_t meta;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_1(bit<8> p) {
    }
    @name(".do_nothing") action do_nothing_0() {
    }
    @name("table_0") table table_1 {
        actions = {
            action_1();
            do_nothing_0();
            @default_only NoAction();
        }
        key = {
            hdr.ethernet.isValid(): ternary @name("hdr.ethernet.isValid()") ;
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
            hdr.ethernet.etherType: exact @name("hdr.ethernet.etherType") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.ethernet.isValid()) 
            table_1.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
