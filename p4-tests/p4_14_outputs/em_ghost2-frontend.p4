#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<12> n1;
    bit<4>  n2;
    bit<8>  b_out;
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
    @name(".setb_out") action setb_out_0(bit<8> val, bit<9> port) {
        hdr.data.b_out = val;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop_0() {
    }
    @name("test1") table test1_0 {
        actions = {
            setb_out_0();
            noop_0();
            @default_only NoAction();
        }
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
            hdr.data.b2: exact @name("hdr.data.b2") ;
            hdr.data.b3: exact @name("hdr.data.b3") ;
            hdr.data.n2: exact @name("hdr.data.n2") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        test1_0.apply();
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
