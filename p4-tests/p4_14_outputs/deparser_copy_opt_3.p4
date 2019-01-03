#include <core.p4>
#include <v1model.p4>

@command_line("--decaf") header data_t {
    bit<8>  m;
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
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
        packet.extract(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a1") action a1() {
        {
            bit<32> temp = hdr.data.a;
            hdr.data.a = hdr.data.b;
            hdr.data.b = (bit<32>)temp;
        }
    }
    @name(".a2") action a2() {
        {
            bit<32> temp_0 = hdr.data.c;
            hdr.data.c = hdr.data.d;
            hdr.data.d = (bit<32>)temp_0;
        }
    }
    @name(".a3") action a3() {
        {
            bit<32> temp_1 = hdr.data.a;
            hdr.data.a = hdr.data.c;
            hdr.data.c = (bit<32>)temp_1;
        }
    }
    @name(".a4") action a4() {
        {
            bit<32> temp_2 = hdr.data.b;
            hdr.data.b = hdr.data.d;
            hdr.data.d = (bit<32>)temp_2;
        }
    }
    @name(".paws") table paws {
        actions = {
            a1;
            a2;
            a3;
            a4;
        }
        key = {
            hdr.data.m: exact;
        }
    }
    apply {
        paws.apply();
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

