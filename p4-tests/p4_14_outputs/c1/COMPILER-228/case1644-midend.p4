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
    @name("m1") 
    M1 m1;
    @name("m2") 
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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_7() {
    }
    @name("NoAction") action NoAction_8() {
    }
    @name("NoAction") action NoAction_9() {
    }
    @name("NoAction") action NoAction_10() {
    }
    @name("NoAction") action NoAction_11() {
    }
    @name(".a1") action _a1() {
        meta.m2.f13 = meta.m1.f4;
        meta.m2.f14 = meta.m1.f5;
        meta.m2.f11 = meta.m1.f1;
    }
    @name(".T1") table _T1_0 {
        actions = {
            _a1();
            @defaultonly NoAction_0();
        }
        size = 1;
        default_action = NoAction_0();
    }
    @name(".a2") action _a2() {
        meta.m2.f17 = 1w1;
        meta.m2.f15 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a3") action _a3() {
    }
    @name(".a6") action _a6() {
        meta.m2.f20 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a7") action _a7(bit<12> f12) {
        meta.m2.f19 = 1w1;
        meta.m2.f12 = f12;
    }
    @name(".a8") action _a8(bit<13> f16) {
        meta.m2.f18 = 1w1;
        meta.m2.f16 = f16;
    }
    @name(".a9") action _a9() {
    }
    @name(".a4") action _a4() {
        meta.m2.f18 = 1w1;
        meta.m2.f21 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11 + 13w0x1;
    }
    @ways(1) @name(".T2") table _T2_0 {
        actions = {
            _a2();
            _a3();
            @defaultonly NoAction_7();
        }
        key = {
            meta.m1.f4: exact @name("meta.m1.f4") ;
        }
        size = 1;
        default_action = NoAction_7();
    }
    @name(".T3") table _T3_0 {
        actions = {
            _a6();
            @defaultonly NoAction_8();
        }
        size = 1;
        default_action = NoAction_8();
    }
    @name(".T4") table _T4_0 {
        actions = {
            _a7();
            _a8();
            _a9();
            @defaultonly NoAction_9();
        }
        key = {
            meta.m1.f4: exact @name("meta.m1.f4") ;
            meta.m1.f1: exact @name("meta.m1.f1") ;
        }
        size = 64;
        default_action = NoAction_9();
    }
    @name(".T6") table _T6_0 {
        actions = {
            _a4();
            @defaultonly NoAction_10();
        }
        size = 1;
        default_action = NoAction_10();
    }
    @name(".a10") action _a10() {
    }
    @name(".T5") table _T5_0 {
        actions = {
            _a10();
            @defaultonly NoAction_11();
        }
        key = {
            meta.m2.f16: exact @name("meta.m2.f16") ;
        }
        size = 1;
        default_action = NoAction_11();
    }
    apply {
        _T1_0.apply();
        switch (_T4_0.apply().action_run) {
            _a9: {
                switch (_T2_0.apply().action_run) {
                    _a3: {
                        if (meta.m1.f7 == 5w0x0) 
                            _T6_0.apply();
                        else 
                            _T3_0.apply();
                    }
                }

            }
        }

        _T5_0.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
