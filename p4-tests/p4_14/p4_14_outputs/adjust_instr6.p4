#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<16> read;
    bit<32> f1;
    bit<8>  b1;
    bit<8>  b2;
    bit<2>  x1;
    bit<2>  x2;
    bit<2>  x3;
    bit<2>  x4;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".bitmasked_adt") action bitmasked_adt(bit<2> param1, bit<2> param2, bit<32> param3) {
        hdr.data.x1 = param1;
        hdr.data.x3 = param2;
        hdr.data.f1 = param3;
    }
    @name(".bitmasked_immed") action bitmasked_immed(bit<2> param1, bit<2> param2, bit<8> param3) {
        hdr.data.x1 = param1;
        hdr.data.x3 = param2;
        hdr.data.b1 = param3;
    }
    @name(".bitmasked_immed2") action bitmasked_immed2(bit<2> param1, bit<2> param2, bit<8> param3, bit<8> param4) {
        hdr.data.x2 = param1;
        hdr.data.x4 = param2;
        hdr.data.b1 = param3;
        hdr.data.b2 = param4;
    }
    @name(".port_setter") table port_setter {
        actions = {
            set_port;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    @name(".test1") table test1 {
        actions = {
            bitmasked_adt;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            bitmasked_immed;
            bitmasked_immed2;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    apply {
        test1.apply();
        test2.apply();
        port_setter.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

