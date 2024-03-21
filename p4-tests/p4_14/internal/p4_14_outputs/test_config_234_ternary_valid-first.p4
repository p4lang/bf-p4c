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
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_0(bit<8> p) {
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): ternary @name("valid") ;
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
            hdr.ethernet.etherType: exact @name("ethernet.etherType") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.ethernet.isValid()) 
            table_0.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

