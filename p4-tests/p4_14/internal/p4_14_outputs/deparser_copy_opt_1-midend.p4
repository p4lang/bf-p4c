#include <core.p4>
#include <v1model.p4>

@command_line("--decaf") header data_t {
    bit<8>  m;
    bit<8>  k;
    bit<16> a;
    bit<16> b;
    bit<16> c;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        standard_metadata.egress_spec = 9w0x2;
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".a1") action a1() {
        hdr.data.a = hdr.data.b;
    }
    @name(".a2") action a2() {
        hdr.data.a = 16w0x800;
    }
    @name(".a3") action a3() {
        hdr.data.a = hdr.data.c;
    }
    @name(".a4") action a4() {
        hdr.data.b = hdr.data.a;
    }
    @name(".a5") action a5() {
        hdr.data.b = 16w0x866;
    }
    @name(".t1") table t1_0 {
        actions = {
            a1();
            a2();
            a3();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.m: exact @name("data.m") ;
        }
        default_action = NoAction_0();
    }
    @name(".t2") table t2_0 {
        actions = {
            a4();
            a5();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.k: exact @name("data.k") ;
        }
        default_action = NoAction_3();
    }
    apply {
        t1_0.apply();
        t2_0.apply();
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

