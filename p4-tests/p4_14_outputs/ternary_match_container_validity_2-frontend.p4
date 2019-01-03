#include <core.p4>
#include <v1model.p4>

header eth_t {
    bit<16> type;
    bit<32> foo;
}

header v4_t {
    bit<32> foo;
}

header v6_t {
    bit<32> foo;
}

struct metadata {
}

struct headers {
    @name(".eth") 
    eth_t eth;
    @name(".v4") 
    v4_t  v4;
    @name(".v6") 
    v6_t  v6;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_v4") state parse_v4 {
        packet.extract<v4_t>(hdr.v4);
        transition accept;
    }
    @name(".parse_v6") state parse_v6 {
        packet.extract<v6_t>(hdr.v6);
        transition accept;
    }
    @name(".start") state start {
        packet.extract<eth_t>(hdr.eth);
        transition select(hdr.eth.type) {
            16w0x8080: parse_v4;
            16w0x5050: parse_v6;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".rewrite_eth") action rewrite_eth() {
        hdr.eth.foo = 32w0x3030303;
    }
    @name(".noop") action noop() {
    }
    @name(".test2") table test2_0 {
        actions = {
            rewrite_eth();
            noop();
        }
        key = {
            hdr.v4.foo      : ternary @name("v4.foo") ;
            hdr.v6.foo      : ternary @name("v6.foo") ;
            hdr.v4.isValid(): exact @name("v4.$valid$") ;
            hdr.v6.isValid(): exact @name("v6.$valid$") ;
        }
        size = 1024;
        default_action = noop();
    }
    apply {
        test2_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w0x2;
    }
    @name(".noop") action noop_2() {
    }
    @name(".test1") table test1_0 {
        actions = {
            set_port();
            noop_2();
        }
        key = {
            hdr.eth.foo: exact @name("eth.foo") ;
        }
        default_action = noop_2();
    }
    apply {
        test1_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<eth_t>(hdr.eth);
        packet.emit<v6_t>(hdr.v6);
        packet.emit<v4_t>(hdr.v4);
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

