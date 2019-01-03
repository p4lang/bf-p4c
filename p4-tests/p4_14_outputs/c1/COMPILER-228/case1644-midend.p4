#include <core.p4>
#include <v1model.p4>

struct M1 {
    bit<12> f1;
    bit<36> f2;
    bit<1>  f3;
    bit<48> f4;
    bit<48> f5;
    bit<1>  f6;
    bit<5>  f7;
}

struct M2 {
    bit<12> f11;
    bit<12> f12;
    bit<48> f13;
    bit<48> f14;
    bit<1>  f15;
    bit<13> f16;
    bit<1>  f17;
    bit<1>  f18;
    bit<1>  f19;
    bit<1>  f20;
    bit<1>  f21;
}

struct metadata {
    @name(".m1") 
    M1 m1;
    @name(".m2") 
    M2 m2;
}

struct headers {
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".NoAction") action NoAction_8() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".a1") action _a1_0() {
        meta.m2.f13 = meta.m1.f4;
        meta.m2.f14 = meta.m1.f5;
        meta.m2.f11 = meta.m1.f1;
    }
    @name(".T1") table _T1 {
        actions = {
            _a1_0();
            @defaultonly NoAction_0();
        }
        size = 1;
        default_action = NoAction_0();
    }
    @name(".a2") action _a2_0() {
        meta.m2.f17 = 1w1;
        meta.m2.f15 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a3") action _a3_0() {
    }
    @name(".a6") action _a6_0() {
        meta.m2.f20 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a7") action _a7_0(bit<12> f12) {
        meta.m2.f19 = 1w1;
        meta.m2.f12 = f12;
    }
    @name(".a8") action _a8_0(bit<13> f16) {
        meta.m2.f18 = 1w1;
        meta.m2.f16 = f16;
    }
    @name(".a9") action _a9_0() {
    }
    @name(".a4") action _a4_0() {
        meta.m2.f18 = 1w1;
        meta.m2.f21 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11 + 13w0x1;
    }
    @ways(1) @name(".T2") table _T2 {
        actions = {
            _a2_0();
            _a3_0();
            @defaultonly NoAction_7();
        }
        key = {
            meta.m1.f4: exact @name("m1.f4") ;
        }
        size = 1;
        default_action = NoAction_7();
    }
    @name(".T3") table _T3 {
        actions = {
            _a6_0();
            @defaultonly NoAction_8();
        }
        size = 1;
        default_action = NoAction_8();
    }
    @name(".T4") table _T4 {
        actions = {
            _a7_0();
            _a8_0();
            _a9_0();
            @defaultonly NoAction_9();
        }
        key = {
            meta.m1.f4: exact @name("m1.f4") ;
            meta.m1.f1: exact @name("m1.f1") ;
        }
        size = 64;
        default_action = NoAction_9();
    }
    @name(".T6") table _T6 {
        actions = {
            _a4_0();
            @defaultonly NoAction_10();
        }
        size = 1;
        default_action = NoAction_10();
    }
    @name(".a10") action _a10_0() {
    }
    @name(".T5") table _T5 {
        actions = {
            _a10_0();
            @defaultonly NoAction_11();
        }
        key = {
            meta.m2.f16: exact @name("m2.f16") ;
        }
        size = 1;
        default_action = NoAction_11();
    }
    apply {
        _T1.apply();
        switch (_T4.apply().action_run) {
            _a9_0: {
                switch (_T2.apply().action_run) {
                    _a3_0: {
                        if (meta.m1.f7 == 5w0x0) 
                            _T6.apply();
                        else 
                            _T3.apply();
                    }
                }

            }
        }

        _T5.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
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

