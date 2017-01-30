#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<8> a;
    bit<8> w;
    bit<8> x;
    bit<8> y;
    bit<8> z;
}

header hdr0_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

struct metadata {
    @name("meta") 
    meta_t meta;
}

struct headers {
    @name("hdr0") 
    hdr0_t hdr0;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        transition accept;
    }
    @name("start") state start {
        transition p_hdr0;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_1") action NoAction_0() {
    }
    @name("NoAction_2") action NoAction_3() {
    }
    @name("meter_0") direct_meter<bit<8>>(CounterType.packets) meter_0;
    @name("action_2") action action_0() {
        hdr.hdr0.a = 16w1;
        meta.meta.a = 8w0;
    }
    @name("do_nothing") action do_nothing_0() {
    }
    @name("action_0") action action_0_1() {
        meta.meta.y = 8w1;
        meter_0.read(meta.meta.x);
    }
    @name("action_1") action action_1() {
        meta.meta.z = 8w0;
        meter_0.read(meta.meta.x);
    }
    @name("table_0") table table_0() {
        actions = {
            action_0_1();
            action_1();
            @default_only NoAction_0();
        }
        key = {
            hdr.hdr0.a: ternary @name("hdr.hdr0.a") ;
        }
        size = 512;
        default_action = NoAction_0();
        meters = meter_0;
    }
    @name("table_1") table table_1() {
        actions = {
            action_0();
            do_nothing_0();
            @default_only NoAction_3();
        }
        key = {
            hdr.hdr0.a: ternary @name("hdr.hdr0.a") ;
        }
        size = 512;
        default_action = NoAction_3();
    }
    apply {
        table_0.apply();
        if (hdr.hdr0.isValid()) 
            table_1.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
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
