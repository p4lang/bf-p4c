#include <core.p4>
#include <v1model.p4>

@command_line("--decaf") header data_t {
    bit<8>  m;
    bit<8>  k;
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
    @name(".a4") action a4() {
        hdr.data.a = hdr.data.d;
    }
    @name(".a5") action a5() {
        hdr.data.b = hdr.data.d;
    }
    @name(".a6") action a6() {
        hdr.data.c = hdr.data.d;
    }
    @name(".demux_1to3") table demux_1to3 {
        actions = {
            a4;
            a5;
            a6;
        }
        key = {
            hdr.data.k: exact;
        }
    }
    apply {
        demux_1to3.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a1") action a1() {
        hdr.data.d = hdr.data.a;
    }
    @name(".a2") action a2() {
        hdr.data.d = hdr.data.b;
    }
    @name(".a3") action a3() {
        hdr.data.d = hdr.data.c;
    }
    @name(".mux_3to1") table mux_3to1 {
        actions = {
            a1;
            a2;
            a3;
        }
        key = {
            hdr.data.m: exact;
        }
    }
    apply {
        mux_3to1.apply();
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

