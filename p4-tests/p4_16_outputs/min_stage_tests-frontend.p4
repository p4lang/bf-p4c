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
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name(".NoAction") action NoAction_23() {
    }
    bool tmp_3;
    bool tmp_4;
    bool tmp_5;
    @name("ingress.setb1") action setb1_0(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.setb1") action setb1_4(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.setb1") action setb1_5(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.setb1") action setb1_6(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.noop") action noop_0() {
    }
    @name("ingress.noop") action noop_1() {
    }
    @name("ingress.noop") action noop_8() {
    }
    @name("ingress.noop") action noop_9() {
    }
    @name("ingress.noop") action noop_10() {
    }
    @name("ingress.noop") action noop_11() {
    }
    @name("ingress.A") table A {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_0();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("ingress.B") table B {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1_0();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    @name("ingress.C") table C {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_1();
            @defaultonly NoAction_16();
        }
        default_action = NoAction_16();
    }
    @name("ingress.X") table X {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_8();
            @defaultonly NoAction_17();
        }
        default_action = NoAction_17();
    }
    @name("ingress.Y") table Y {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_9();
            @defaultonly NoAction_18();
        }
        default_action = NoAction_18();
    }
    @name("ingress.X2") table X2 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_10();
            @defaultonly NoAction_19();
        }
        default_action = NoAction_19();
    }
    @name("ingress.Y2") table Y2 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_11();
            @defaultonly NoAction_20();
        }
        default_action = NoAction_20();
    }
    @name("ingress.Z1") table Z1 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_4();
            @defaultonly NoAction_21();
        }
        default_action = NoAction_21();
    }
    @name("ingress.Z2") table Z2 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_5();
            @defaultonly NoAction_22();
        }
        default_action = NoAction_22();
    }
    @name("ingress.Z3") table Z3 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_6();
            @defaultonly NoAction_23();
        }
        default_action = NoAction_23();
    }
    apply {
        tmp_5 = A.apply().hit;
        if (tmp_5) {
            tmp_3 = B.apply().hit;
            if (tmp_3) 
                X.apply();
            else 
                Y.apply();
        }
        else {
            tmp_4 = C.apply().hit;
            if (tmp_4) 
                X2.apply();
            else 
                Y2.apply();
        }
        Z1.apply();
        Z2.apply();
        Z3.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_24() {
    }
    @name(".NoAction") action NoAction_25() {
    }
    @name(".NoAction") action NoAction_26() {
    }
    @name(".NoAction") action NoAction_27() {
    }
    bool tmp_6;
    @name("egress.setf2") action setf2_0(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.setf2") action setf2_3(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.setf2") action setf2_4(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.noop") action noop_12() {
    }
    @name("egress.alpha") table alpha {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2_0();
            @defaultonly NoAction_24();
        }
        default_action = NoAction_24();
    }
    @name("egress.beta") table beta {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2_3();
            @defaultonly NoAction_25();
        }
        default_action = NoAction_25();
    }
    @name("egress.gamma") table gamma {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2_4();
            @defaultonly NoAction_26();
        }
        default_action = NoAction_26();
    }
    @name("egress.t2") table t2 {
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
        }
        actions = {
            noop_12();
            @defaultonly NoAction_27();
        }
        default_action = NoAction_27();
    }
    apply {
        alpha.apply();
        tmp_6 = beta.apply().hit;
        if (tmp_6) 
            t2.apply();
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

V1Switch<headers, Meta>(ParserImpl(), vrfy(), ingress(), egress(), update(), deparser()) main;

