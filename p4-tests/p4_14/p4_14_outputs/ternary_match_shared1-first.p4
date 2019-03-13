#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<80> b7;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.b1: ternary @name("data.b1") ;
            hdr.data.b2: ternary @name("data.b2") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.b3: ternary @name("data.b3") ;
            hdr.data.b4: ternary @name("data.b4") ;
            hdr.data.b5: ternary @name("data.b5") ;
        }
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.b1: ternary @name("data.b1") ;
            hdr.data.b2: ternary @name("data.b2") ;
            hdr.data.b3: ternary @name("data.b3") ;
            hdr.data.b4: ternary @name("data.b4") ;
            hdr.data.b7: ternary @name("data.b7") ;
        }
        default_action = NoAction();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
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

