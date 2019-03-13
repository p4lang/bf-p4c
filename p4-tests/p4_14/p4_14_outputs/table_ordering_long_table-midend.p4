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
    bool tmp;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".NoAction") action NoAction_12() {
    }
    @name(".NoAction") action NoAction_13() {
    }
    @name(".NoAction") action NoAction_14() {
    }
    @name(".NoAction") action NoAction_15() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_2() {
    }
    @name(".setb1") action setb1(bit<32> val, bit<8> port) {
        hdr.data.b1 = val;
    }
    @name(".setb1") action setb1_5(bit<32> val, bit<8> port) {
        hdr.data.b1 = val;
    }
    @name(".setb1") action setb1_6(bit<32> val, bit<8> port) {
        hdr.data.b1 = val;
    }
    @name(".setb1") action setb1_7(bit<32> val, bit<8> port) {
        hdr.data.b1 = val;
    }
    @name(".setb1") action setb1_8(bit<32> val, bit<8> port) {
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
    @name(".t1") table t1_0 {
        actions = {
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        size = 8192;
        default_action = NoAction_0();
    }
    @name(".t10") table t10_0 {
        actions = {
            setb1();
            @defaultonly NoAction_11();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction_11();
    }
    @name(".t2") table t2_0 {
        actions = {
            setb1_5();
            noop_2();
            @defaultonly NoAction_12();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        size = 8192;
        default_action = NoAction_12();
    }
    @name(".t3") table t3_0 {
        actions = {
            setf7();
            @defaultonly NoAction_13();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 65536;
        default_action = NoAction_13();
    }
    @name(".t4") table t4_0 {
        actions = {
            setf8();
            @defaultonly NoAction_14();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 65536;
        default_action = NoAction_14();
    }
    @name(".t5") table t5_0 {
        actions = {
            setf9();
            @defaultonly NoAction_15();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 105536;
        default_action = NoAction_15();
    }
    @name(".t6") table t6_0 {
        actions = {
            setf10();
            @defaultonly NoAction_16();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        size = 95536;
        default_action = NoAction_16();
    }
    @name(".t7") table t7_0 {
        actions = {
            setb1_6();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = NoAction_17();
    }
    @name(".t8") table t8_0 {
        actions = {
            setb1_7();
            @defaultonly NoAction_18();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction_18();
    }
    @name(".t9") table t9_0 {
        actions = {
            setb1_8();
            @defaultonly NoAction_19();
        }
        key = {
            hdr.data.f2: exact @name("data.f2") ;
        }
        default_action = NoAction_19();
    }
    @hidden action act() {
        tmp = true;
    }
    @hidden action act_0() {
        tmp = false;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        if (t1_0.apply().hit) 
            tbl_act.apply();
        else 
            tbl_act_0.apply();
        if (tmp) 
            t2_0.apply();
        t3_0.apply();
        t4_0.apply();
        t5_0.apply();
        t6_0.apply();
        t7_0.apply();
        t8_0.apply();
        t9_0.apply();
        t10_0.apply();
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

