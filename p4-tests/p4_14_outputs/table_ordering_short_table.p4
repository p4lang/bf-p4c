#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> b1;
    bit<32> b2;
    bit<32> f1;
    bit<32> f2;
    bit<32> f7;
    bit<32> f8;
    bit<32> f9;
    bit<32> f10;
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
    @name(".noop") action noop() {
    }
    @name(".setb1") action setb1(bit<32> val, bit<8> port) {
        hdr.data.b1 = val;
    }
    @name(".setf7") action setf7(bit<32> val) {
        hdr.data.f7 = val;
    }
    @name(".setf8") action setf8(bit<32> val) {
        hdr.data.f8 = val;
    }
    @name(".setf9") action setf9(bit<32> val) {
        hdr.data.f9 = val;
    }
    @name(".setf10") action setf10(bit<32> val) {
        hdr.data.f10 = val;
    }
    @name(".t1") table t1 {
        actions = {
            noop;
        }
        key = {
            hdr.data.f2: exact;
        }
        size = 8192;
    }
    @name(".t10") table t10 {
        actions = {
            setb1;
        }
        key = {
            hdr.data.f2: exact;
        }
    }
    @name(".t2") table t2 {
        actions = {
            setb1;
            noop;
        }
        key = {
            hdr.data.b1: exact;
        }
        size = 8192;
    }
    @name(".t3") table t3 {
        actions = {
            setf7;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 65536;
    }
    @name(".t4") table t4 {
        actions = {
            setf8;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 65536;
    }
    @name(".t5") table t5 {
        actions = {
            setf9;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 95536;
    }
    @name(".t6") table t6 {
        actions = {
            setf10;
        }
        key = {
            hdr.data.f1: exact;
        }
        size = 95536;
    }
    @name(".t7") table t7 {
        actions = {
            setb1;
        }
        key = {
            hdr.data.b1: exact;
        }
    }
    @name(".t8") table t8 {
        actions = {
            setb1;
        }
        key = {
            hdr.data.f2: exact;
        }
    }
    @name(".t9") table t9 {
        actions = {
            setb1;
        }
        key = {
            hdr.data.f2: exact;
        }
    }
    apply {
        if (t1.apply().hit) {
            t2.apply();
        }
        t3.apply();
        t4.apply();
        t5.apply();
        t6.apply();
        t7.apply();
        t8.apply();
        t9.apply();
        t10.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

