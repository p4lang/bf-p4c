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
    action a1(bit<8> val) {
        hdr.data.b1 = val;
    }
    action noop() {
    }
    table t1 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            a1();
            noop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    table t2 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    table t3 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    table t4 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        switch (t1.apply().action_run) {
            default: {
                if (hdr.data.f2 == hdr.data.f1) {
                    t2.apply();
                    switch (t3.apply().action_run) {
                        noop: {
                            t4.apply();
                        }
                    }

                }
            }
            a1: {
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

