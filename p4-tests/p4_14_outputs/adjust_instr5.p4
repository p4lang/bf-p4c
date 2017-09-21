#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<16> read;
    bit<32> f1;
    bit<8>  b1;
    bit<4>  n1;
    bit<4>  n2;
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
    @name(".constant_conversion_adt") action constant_conversion_adt(bit<4> param1, bit<32> param2) {
        hdr.data.n1 = 4w4;
        hdr.data.n2 = param1;
        hdr.data.f1 = param2;
    }
    @name(".constant_conversion_adt2") action constant_conversion_adt2(bit<4> param1) {
        hdr.data.n1 = 4w9;
        hdr.data.n2 = param1;
        hdr.data.f1 = 32w0x77777f77;
    }
    @name(".constant_conversion_immed") action constant_conversion_immed(bit<4> param1) {
        hdr.data.n1 = 4w7;
        hdr.data.n2 = param1;
        hdr.data.b1 = 8w0xab;
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
            constant_conversion_adt;
            constant_conversion_adt2;
        }
        key = {
            hdr.data.read: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            constant_conversion_immed;
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
