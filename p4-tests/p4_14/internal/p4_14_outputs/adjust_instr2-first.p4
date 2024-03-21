#include <core.p4>
#include <v1model.p4>

struct nibble_meta_t {
    bit<2> hn1;
    bit<2> hn2;
    bit<4> n1;
}

header hdr_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<4>  n1;
    bit<2>  hn1;
    bit<2>  hn2;
    bit<4>  n2;
    bit<2>  hn3;
    bit<2>  hn4;
}

struct metadata {
    @name(".nibble_meta") 
    nibble_meta_t nibble_meta;
}

struct headers {
    @name(".hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<hdr_t>(hdr.hdr);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_fields") action set_fields(bit<32> big_field, bit<2> half_nibble1, bit<2> half_nibble2) {
        hdr.hdr.f4 = big_field;
        hdr.hdr.hn1 = half_nibble1;
        hdr.hdr.hn2 = half_nibble2;
    }
    @name(".back_to_hdr") action back_to_hdr() {
        hdr.hdr.hn2 = meta.nibble_meta.hn1;
        hdr.hdr.hn4 = meta.nibble_meta.hn2;
    }
    @name(".set_nibble_meta") action set_nibble_meta() {
        meta.nibble_meta.hn1 = hdr.hdr.hn1;
        meta.nibble_meta.hn2 = hdr.hdr.hn2;
    }
    @name(".set_all") table set_all {
        actions = {
            set_fields();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr.f1: exact @name("hdr.f1") ;
        }
        default_action = NoAction();
    }
    @name(".set_back") table set_back {
        actions = {
            back_to_hdr();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr.f3: exact @name("hdr.f3") ;
        }
        default_action = NoAction();
    }
    @name(".set_nibbles") table set_nibbles {
        actions = {
            set_nibble_meta();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr.f2: exact @name("hdr.f2") ;
        }
        default_action = NoAction();
    }
    apply {
        set_all.apply();
        set_nibbles.apply();
        set_back.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr_t>(hdr.hdr);
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

