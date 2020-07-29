#include <core.p4>
#include <v1model.p4>
#include <tofino/stateful_alu.p4>

struct metadata {
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<16>>(32w2048) accum;
    RegisterAction<bit<16>, bit<32>, bit<16>>(accum) logh1 = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };
    RegisterAction<bit<16>, bit<32>, bit<16>>(accum) query = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
        }
    };
    action logit(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 8w0xff;
        logh1.execute_log();
    }
    table do_log {
        actions = {
            logit();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
        }
        default_action = NoAction();
    }
    action getit(bit<11> index, bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 8w0xfe;
        hdr.data.h1 = query.execute((bit<32>)index);
    }
    table do_query {
        actions = {
            getit();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.data.b1 == 8w0) 
            do_query.apply();
        else 
            do_log.apply();
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
