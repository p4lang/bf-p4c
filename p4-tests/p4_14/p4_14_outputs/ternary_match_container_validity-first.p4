#include <core.p4>
#include <v1model.p4>

struct wred_metadata_t {
    bit<8> index;
}

header data_t {
    bit<32> foo;
}

struct metadata {
    @name(".wred_metadata") 
    wred_metadata_t wred_metadata;
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

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_index") action set_index() {
        meta.wred_metadata.index = 8w0x1;
    }
    @name(".rewrite_data") action rewrite_data() {
        hdr.data.foo = 32w0x3030303;
    }
    @name(".noop") action noop() {
    }
    @name(".test2") table test2 {
        actions = {
            set_index();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.foo: exact @name("data.foo") ;
        }
        default_action = NoAction();
    }
    @name(".test3") table test3 {
        actions = {
            rewrite_data();
            noop();
        }
        key = {
            meta.wred_metadata.index: exact @name("wred_metadata.index") ;
            hdr.data.foo            : ternary @name("data.foo") ;
        }
        size = 1024;
        default_action = noop();
    }
    apply {
        test2.apply();
        test3.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w0x2;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            set_port();
            noop();
        }
        key = {
            hdr.data.foo: exact @name("data.foo") ;
        }
        default_action = noop();
    }
    apply {
        test1.apply();
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

