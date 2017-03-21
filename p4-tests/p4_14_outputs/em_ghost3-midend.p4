#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<2> x1;
    bit<4> n1;
    bit<2> x2;
    bit<2> x3;
    bit<4> n2;
    bit<2> x4;
    bit<2> x5;
    bit<4> n3;
    bit<2> x6;
    bit<8> b1;
    bit<8> b2;
    bit<8> b_out;
}

struct metadata {
}

struct headers {
    @name("data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction") action NoAction_0() {
    }
    @name("setb_out") action setb_out_0(bit<8> val, bit<9> port) {
        hdr.data.b_out = val;
        standard_metadata.egress_spec = port;
    }
    @name("noop") action noop_0() {
    }
    @name("test1") table test1() {
        actions = {
            setb_out_0();
            noop_0();
            @default_only NoAction_0();
        }
        key = {
            hdr.data.n1: exact @name("hdr.data.n1") ;
            hdr.data.n2: exact @name("hdr.data.n2") ;
            hdr.data.n3: exact @name("hdr.data.n3") ;
            hdr.data.b1: exact @name("hdr.data.b1") ;
            hdr.data.b2: exact @name("hdr.data.b2") ;
        }
        default_action = NoAction_0();
    }
    apply {
        test1.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
