#include <core.p4>
#include <v1model.p4>

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
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name("ingress.a1") action a1_0(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.noop") action noop_0() {
    }
    @name("ingress.noop") action noop_4() {
    }
    @name("ingress.noop") action noop_5() {
    }
    @name("ingress.noop") action noop_6() {
    }
    @name("ingress.t1") table t1 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            a1_0();
            noop_0();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("ingress.t2") table t2 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_4();
            @defaultonly NoAction_5();
        }
        default_action = NoAction_5();
    }
    @name("ingress.t3") table t3 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_5();
            @defaultonly NoAction_6();
        }
        default_action = NoAction_6();
    }
    @name("ingress.t4") table t4 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_6();
            @defaultonly NoAction_7();
        }
        default_action = NoAction_7();
    }
    apply {
        switch (t1.apply().action_run) {
            default: {
                if (hdr.data.f2 == hdr.data.f1) {
                    t2.apply();
                    switch (t3.apply().action_run) {
                        noop_5: {
                            t4.apply();
                        }
                    }

                }
            }
            a1_0: {
                t4.apply();
            }
        }

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

