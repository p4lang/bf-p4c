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
        packet.extract<data_t>(hdr.data);
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
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @name(".t10") table t10 {
        actions = {
            setb1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction();
    }
    @name(".t2") table t2 {
        actions = {
            setb1();
            noop();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        size = 8192;
        default_action = NoAction();
    }
    @name(".t3") table t3 {
        actions = {
            setf7();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    @name(".t4") table t4 {
        actions = {
            setf8();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 65536;
        default_action = NoAction();
    }
    @name(".t5") table t5 {
        actions = {
            setf9();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 105536;
        default_action = NoAction();
    }
    @name(".t6") table t6 {
        actions = {
            setf10();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 95536;
        default_action = NoAction();
    }
    @name(".t7") table t7 {
        actions = {
            setb1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = NoAction();
    }
    @name(".t8") table t8 {
        actions = {
            setb1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction();
    }
    @name(".t9") table t9 {
        actions = {
            setb1();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction();
    }
    apply {
        if (t1.apply().hit) 
            t2.apply();
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

