#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

struct headers {
    @name("data") 
    data_t data;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp_0;
    @name("NoAction") action NoAction_0() {
    }
    @name(".accum") register<bit<16>>(32w0) accum;
    @name("sful") register_action<bit<16>, bit<16>>(accum) sful = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = value + (bit<16>)hdr.data.b1;
        }
    };
    @name(".addb1") action addb1_0(bit<9> port) {
        standard_metadata.egress_spec = port;
        tmp_0 = sful.execute();
        hdr.data.h1 = tmp_0;
    }
    @name(".test1") table test1 {
        actions = {
            addb1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
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
