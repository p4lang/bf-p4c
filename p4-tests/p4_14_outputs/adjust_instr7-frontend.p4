#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<16> read;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<26> t1;
    bit<2>  x1;
    bit<2>  x2;
    bit<2>  x3;
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
    @name(".setport") action setport_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".bitmasked_full") action bitmasked_full_0(bit<26> param1, bit<2> param2) {
        hdr.data.t1 = param1;
        hdr.data.x2 = param2;
    }
    @name(".all_bytes") action all_bytes_0(bit<8> byte1, bit<8> byte2, bit<8> byte3, bit<8> byte4) {
        hdr.data.b1 = byte1;
        hdr.data.b2 = byte2;
        hdr.data.b3 = byte3;
        hdr.data.b4 = byte4;
    }
    @name(".some_halves") action some_halves_0(bit<16> half1, bit<16> half2) {
        hdr.data.h1 = half1;
        hdr.data.h2 = half2;
    }
    @name(".bitmasked_full2") action bitmasked_full2_0(bit<26> param1, bit<2> param2) {
        hdr.data.t1 = param1;
        hdr.data.x2 = param2;
    }
    @name(".all_halves") action all_halves_0(bit<16> half1, bit<16> half2, bit<16> half3, bit<16> half4) {
        hdr.data.h1 = half1;
        hdr.data.h2 = half2;
        hdr.data.h3 = half3;
        hdr.data.h4 = half4;
    }
    @name(".port_setter") table port_setter_0 {
        actions = {
            setport_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.read: exact @name("data.read") ;
        }
        default_action = NoAction();
    }
    @name(".test1") table test1_0 {
        actions = {
            bitmasked_full_0();
            all_bytes_0();
            some_halves_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.read: exact @name("data.read") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2_0 {
        actions = {
            bitmasked_full2_0();
            all_halves_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.read: exact @name("data.read") ;
        }
        default_action = NoAction();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        port_setter_0.apply();
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

