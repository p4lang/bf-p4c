#include <core.p4>
#include <v1model.p4>

header one_t {
    bit<16> a;
}

header three_t {
    bit<8> a;
}

header two_t {
    bit<16> a;
}

struct metadata {
}

struct headers {
    @pa_container_size("ingress", "one.a", 8) @name(".one") 
    one_t   one;
    @name(".three") 
    three_t three;
    @name(".two") 
    two_t   two;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".p_one") state p_one {
        packet.extract<one_t>(hdr.one);
        transition p_two;
    }
    @name(".p_three") state p_three {
        packet.extract<three_t>(hdr.three);
        transition accept;
    }
    @name(".p_two") state p_two {
        packet.extract<two_t>(hdr.two);
        transition p_three;
    }
    @name(".start") state start {
        transition p_one;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_0() {
        hdr.one.a = hdr.two.a;
    }
    @name(".t_one") table t_one {
        actions = {
            action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.one.a  : ternary @name("one.a") ;
            hdr.two.a  : ternary @name("two.a") ;
            hdr.three.a: ternary @name("three.a") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        t_one.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<one_t>(hdr.one);
        packet.emit<two_t>(hdr.two);
        packet.emit<three_t>(hdr.three);
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

