#include <core.p4>
#include <v1model.p4>

header cc1_t {
    bit<4> x1;
    bit<2> y1;
    bit<2> z1;
    bit<4> x2;
    bit<2> y2;
    bit<2> z2;
}

@pa_container_size("ingress", "cc1.x1", 8) header cc2_t {
    bit<4> u1;
    bit<4> v1;
    bit<4> u2;
    bit<4> v2;
}

header init_t {
    bit<32> read;
    bit<8>  class;
}

struct metadata {
}

struct headers {
    @name(".cc1") 
    cc1_t  cc1;
    @name(".cc2") 
    cc2_t  cc2;
    @name(".init") 
    init_t init;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_cc1") state parse_cc1 {
        packet.extract<cc1_t>(hdr.cc1);
        transition accept;
    }
    @name(".parse_cc2") state parse_cc2 {
        packet.extract<cc2_t>(hdr.cc2);
        transition accept;
    }
    @name(".start") state start {
        packet.extract<init_t>(hdr.init);
        transition select(hdr.init.class) {
            8w0x1: parse_cc1;
            8w0x2: parse_cc2;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_3() {
    }
    @name(".noop") action noop_4() {
    }
    @name(".cc1_act") action cc1_act() {
        hdr.cc1.x1 = hdr.cc1.x2;
        hdr.cc1.z1 = hdr.cc1.z2;
    }
    @name(".cc2_act") action cc2_act() {
        hdr.cc2.u1 = hdr.cc2.v2;
        hdr.cc2.v1 = hdr.cc2.u2;
    }
    @name(".port_action") action port_action(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".cc1_table") table cc1_table_0 {
        actions = {
            noop();
            cc1_act();
        }
        key = {
            hdr.init.read: exact @name("init.read") ;
        }
        default_action = noop();
    }
    @name(".cc2_table") table cc2_table_0 {
        actions = {
            noop_3();
            cc2_act();
        }
        key = {
            hdr.init.read: exact @name("init.read") ;
        }
        default_action = noop_3();
    }
    @name(".port_table") table port_table_0 {
        actions = {
            noop_4();
            port_action();
        }
        key = {
            hdr.init.read: ternary @name("init.read") ;
        }
        default_action = noop_4();
    }
    apply {
        if (hdr.cc1.isValid()) 
            cc1_table_0.apply();
        if (hdr.cc2.isValid()) 
            cc2_table_0.apply();
        port_table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<init_t>(hdr.init);
        packet.emit<cc2_t>(hdr.cc2);
        packet.emit<cc1_t>(hdr.cc1);
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

