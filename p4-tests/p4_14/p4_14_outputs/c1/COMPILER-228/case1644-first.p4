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

control c1(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a1") action a1() {
        meta.m2.f13 = meta.m1.f4;
        meta.m2.f14 = meta.m1.f5;
        meta.m2.f11 = meta.m1.f1;
    }
    @name(".T1") table T1 {
        actions = {
            a1();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        T1.apply();
    }
}

control c2(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a2") action a2() {
        meta.m2.f17 = 1w1;
        meta.m2.f15 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a3") action a3() {
    }
    @name(".a6") action a6() {
        meta.m2.f20 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11;
    }
    @name(".a7") action a7(bit<12> f12) {
        meta.m2.f19 = 1w1;
        meta.m2.f12 = f12;
    }
    @name(".a8") action a8(bit<13> f16) {
        meta.m2.f18 = 1w1;
        meta.m2.f16 = f16;
    }
    @name(".a9") action a9() {
    }
    @name(".a4") action a4() {
        meta.m2.f18 = 1w1;
        meta.m2.f21 = 1w1;
        meta.m2.f16 = (bit<13>)meta.m2.f11 + 13w0x1;
    }
    @ways(1) @name(".T2") table T2 {
        actions = {
            a2();
            a3();
            @defaultonly NoAction();
        }
        key = {
            meta.m1.f4: exact @name("m1.f4") ;
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".T3") table T3 {
        actions = {
            a6();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name(".T4") table T4 {
        actions = {
            a7();
            a8();
            a9();
            @defaultonly NoAction();
        }
        key = {
            meta.m1.f4: exact @name("m1.f4") ;
            meta.m1.f1: exact @name("m1.f1") ;
        }
        size = 64;
        default_action = NoAction();
    }
    @name(".T6") table T6 {
        actions = {
            a4();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        switch (T4.apply().action_run) {
            a9: {
                switch (T2.apply().action_run) {
                    a3: {
                        if (meta.m1.f7 == 5w0x0) 
                            T6.apply();
                        else 
                            T3.apply();
                    }
                }

            }
        }

    }
}

control c3(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a10") action a10() {
    }
    @name(".T5") table T5 {
        actions = {
            a10();
            @defaultonly NoAction();
        }
        key = {
            meta.m2.f16: exact @name("m2.f16") ;
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        T5.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".c1") c1() c1_0;
    @name(".c2") c2() c2_0;
    @name(".c3") c3() c3_0;
    apply {
        c1_0.apply(hdr, meta, standard_metadata);
        c2_0.apply(hdr, meta, standard_metadata);
        c3_0.apply(hdr, meta, standard_metadata);
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

