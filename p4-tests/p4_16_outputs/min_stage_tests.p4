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
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action setb1(bit<8> val) {
        hdr.data.b1 = val;
    }
    action setf2(bit<32> val) {
        hdr.data.f2 = val;
    }
    action noop() {
    }
    table A {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table B {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            setb1;
        }
    }
    table C {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table X {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table Y {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table X2 {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table Y2 {
        key = {
            hdr.data.f1: exact;
        }
        actions = {
            noop;
        }
    }
    table Z1 {
        key = {
            hdr.data.b1: exact;
        }
        actions = {
            setb1;
        }
    }
    table Z2 {
        key = {
            hdr.data.b1: exact;
        }
        actions = {
            setb1;
        }
    }
    table Z3 {
        key = {
            hdr.data.b1: exact;
        }
        actions = {
            setb1;
        }
    }
    apply {
        if (A.apply().hit) {
            if (B.apply().hit) {
                X.apply();
            }
            else {
                Y.apply();
            }
        }
        else {
            if (C.apply().hit) {
                X2.apply();
            }
            else {
                Y2.apply();
            }
        }
        Z1.apply();
        Z2.apply();
        Z3.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action setb1(bit<8> val) {
        hdr.data.b1 = val;
    }
    action setf2(bit<32> val) {
        hdr.data.f2 = val;
    }
    action noop() {
    }
    table alpha {
        key = {
            hdr.data.f2: exact;
        }
        actions = {
            setf2;
        }
    }
    table beta {
        key = {
            hdr.data.f2: exact;
        }
        actions = {
            setf2;
        }
    }
    table gamma {
        key = {
            hdr.data.f2: exact;
        }
        actions = {
            setf2;
        }
    }
    table t2 {
        key = {
            hdr.data.h1: exact;
        }
        actions = {
            noop;
        }
    }
    apply {
        alpha.apply();
        if (beta.apply().hit) {
            t2.apply();
        }
        gamma.apply();
    }
}

struct Meta {
}

control vrfy(inout headers h, inout Meta m) {
    apply {
    }
}

control update(inout headers h, inout Meta m) {
    apply {
    }
}

control deparser(packet_out b, in headers h) {
    apply {
    }
}

V1Switch(ParserImpl(), vrfy(), ingress(), egress(), update(), deparser()) main;

