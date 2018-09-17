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
    bit<16> tmp_0;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name("ingress.accum") register<bit<16>>(32w2048) accum;
    @name("ingress.logh1") RegisterAction<bit<16>, bit<32>, bit<16>>(accum) logh1 = {
        void apply(inout bit<16> value) {
            value = hdr.data.h1;
        }
    };
    @name("ingress.query") RegisterAction<bit<16>, bit<32>, bit<16>>(accum) query = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = value;
        }
    };
    @name("ingress.logit") action logit_0(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 8w0xff;
        logh1.execute_log();
    }
    @name("ingress.do_log") table do_log {
        actions = {
            logit_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
        }
        default_action = NoAction_0();
    }
    @name("ingress.getit") action getit_0(bit<11> index, bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.b1 = 8w0xfe;
        tmp_0 = query.execute((bit<32>)index);
        hdr.data.h1 = tmp_0;
    }
    @name("ingress.do_query") table do_query {
        actions = {
            getit_0();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction_3();
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

