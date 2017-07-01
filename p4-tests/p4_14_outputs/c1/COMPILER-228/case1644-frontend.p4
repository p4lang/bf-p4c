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

control c1(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a1") action a1_0() {
        meta.m2.f13 = meta.m1.f4;
        meta.m2.f14 = meta.m1.f5;
        meta.m2.f11 = meta.m1.f1;
    }
    @name(".T1") table T1_0 {
        actions = {
            a1_0();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        T1_0.apply();
    }
}

control c2(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a2") action a2_0() {
        meta.m2.f17 = 1w1;
        meta.m2.f15 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a3") action a3_0() {
    }
    @name(".a6") action a6_0() {
        meta.m2.f20 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a7") action a7_0(bit<12> f12) {
        meta.m2.f19 = 1w1;
        meta.m2.f12 = f12;
    }
    @name(".a8") action a8_0(bit<13> f16) {
        meta.m2.f18 = 1w1;
        meta.m2.f16 = f16;
    }
    @name(".a9") action a9_0() {
    }
    @name(".a4") action a4_0() {
        meta.m2.f18 = 1w1;
        meta.m2.f21 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11 + 13w0x1;
    }
    @ways(1) @name(".T2") table T2_0 {
        actions = {
            a2_0();
            a3_0();
            @defaultonly NoAction();
        }
        key = {
            meta.m1.f4: exact @name("meta.m1.f4") ;
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".T3") table T3_0 {
        actions = {
            a6_0();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".T4") table T4_0 {
        actions = {
            a7_0();
            a8_0();
            a9_0();
            @defaultonly NoAction();
        }
        key = {
            meta.m1.f4: exact @name("meta.m1.f4") ;
            meta.m1.f1: exact @name("meta.m1.f1") ;
        }
        size = 64;
        default_action = NoAction();
    }
    @name(".T6") table T6_0 {
        actions = {
            a4_0();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        switch (T4_0.apply().action_run) {
            a9_0: {
                switch (T2_0.apply().action_run) {
                    a3_0: {
                        if (meta.m1.f7 == 5w0x0) 
                            T6_0.apply();
                        else 
                            T3_0.apply();
                    }
                }

            }
        }

    }
}

control c3(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a10") action a10_0() {
    }
    @name(".T5") table T5_0 {
        actions = {
            a10_0();
            @defaultonly NoAction();
        }
        key = {
            meta.m2.f16: exact @name("meta.m2.f16") ;
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        T5_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".c1") c1() c1_1;
    @name(".c2") c2() c2_1;
    @name(".c3") c3() c3_1;
    apply {
        c1_1.apply(hdr, meta, standard_metadata);
        c2_1.apply(hdr, meta, standard_metadata);
        c3_1.apply(hdr, meta, standard_metadata);
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
