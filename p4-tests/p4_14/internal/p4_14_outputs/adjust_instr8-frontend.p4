#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<16> read;
    bit<2>  x1;
    bit<2>  x2;
    bit<2>  x3;
    bit<2>  x4;
    bit<4>  y1;
    bit<2>  y2;
    bit<2>  y3;
    bit<2>  u1;
    bit<2>  u2;
    bit<12> u3;
    bit<28> v1;
    bit<2>  v2;
    bit<2>  v3;
}

struct metadata {
}

struct headers {
    @pa_container_size("ingress", "data.x1", 8) @pa_container_size("ingress", "data.y1", 8) @pa_container_size("ingress", "data.u1", 16) @pa_container_size("ingress", "data.v1", 32) @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".a1") action a1() {
        hdr.data.x1 = 2w0;
        hdr.data.x2 = 2w0;
    }
    @name(".a2") action a2() {
        hdr.data.x1 = 2w3;
        hdr.data.x2 = 2w2;
        hdr.data.x3 = 2w0;
    }
    @name(".a3") action a3() {
        hdr.data.y1 = 4w0xe;
        hdr.data.y2 = 2w0x2;
    }
    @name(".a4") action a4() {
        hdr.data.y1 = 4w0x6;
        hdr.data.y2 = 2w0x1;
        hdr.data.y3 = 2w0x1;
    }
    @name(".a5") action a5() {
        hdr.data.u3 = 12w0xffd;
    }
    @name(".a6") action a6() {
        hdr.data.u2 = 2w0x3;
        hdr.data.u3 = 12w0xff8;
    }
    @name(".a7") action a7() {
        hdr.data.v1 = 28w0xffffffe;
        hdr.data.v2 = 2w0x1;
    }
    @name(".set_port") table set_port_0 {
        actions = {
            setport();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.read: ternary @name("data.read") ;
        }
        default_action = NoAction_0();
    }
    @name(".test1") table test1_0 {
        actions = {
            a1();
            a2();
            a3();
            a4();
            a5();
            a6();
            a7();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.read: exact @name("data.read") ;
        }
        default_action = NoAction_3();
    }
    apply {
        test1_0.apply();
        set_port_0.apply();
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

