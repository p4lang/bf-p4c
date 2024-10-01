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
    bool tmp;
    bool tmp_0;
    bool tmp_1;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
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
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name("ingress.setb1") action setb1(bit<8> val) {
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
    @name("ingress.noop") action noop() {
    }
    @name("ingress.noop") action noop_6() {
    }
    @name("ingress.noop") action noop_7() {
    }
    @name("ingress.noop") action noop_8() {
    }
    @name("ingress.noop") action noop_9() {
    }
    @name("ingress.noop") action noop_10() {
    }
    @name("ingress.A") table A_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("ingress.B") table B_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            setb1();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    @name("ingress.C") table C_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_6();
            @defaultonly NoAction_15();
        }
        default_action = NoAction_15();
    }
    @name("ingress.X") table X_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_7();
            @defaultonly NoAction_16();
        }
        default_action = NoAction_16();
    }
    @name("ingress.Y") table Y_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_8();
            @defaultonly NoAction_17();
        }
        default_action = NoAction_17();
    }
    @name("ingress.X2") table X2_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_9();
            @defaultonly NoAction_18();
        }
        default_action = NoAction_18();
    }
    @name("ingress.Y2") table Y2_0 {
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        actions = {
            noop_10();
            @defaultonly NoAction_19();
        }
        default_action = NoAction_19();
    }
    @name("ingress.Z1") table Z1_0 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_4();
            @defaultonly NoAction_20();
        }
        default_action = NoAction_20();
    }
    @name("ingress.Z2") table Z2_0 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_5();
            @defaultonly NoAction_21();
        }
        default_action = NoAction_21();
    }
    @name("ingress.Z3") table Z3_0 {
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
        }
        actions = {
            setb1_6();
            @defaultonly NoAction_22();
        }
        default_action = NoAction_22();
    }
    @hidden action act() {
        tmp_1 = true;
    }
    @hidden action act_0() {
        tmp_1 = false;
    }
    @hidden action act_1() {
        tmp = true;
    }
    @hidden action act_2() {
        tmp = false;
    }
    @hidden action act_3() {
        tmp_0 = true;
    }
    @hidden action act_4() {
        tmp_0 = false;
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
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    @hidden table tbl_act_3 {
        actions = {
            act_3();
        }
        const default_action = act_3();
    }
    @hidden table tbl_act_4 {
        actions = {
            act_4();
        }
        const default_action = act_4();
    }
    apply {
        if (A_0.apply().hit) 
            tbl_act.apply();
        else 
            tbl_act_0.apply();
        if (tmp_1) {
            if (B_0.apply().hit) 
                tbl_act_1.apply();
            else 
                tbl_act_2.apply();
            if (tmp) 
                X_0.apply();
            else 
                Y_0.apply();
        }
        else {
            if (C_0.apply().hit) 
                tbl_act_3.apply();
            else 
                tbl_act_4.apply();
            if (tmp_0) 
                X2_0.apply();
            else 
                Y2_0.apply();
        }
        Z1_0.apply();
        Z2_0.apply();
        Z3_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_23() {
    }
    @name(".NoAction") action NoAction_24() {
    }
    @name(".NoAction") action NoAction_25() {
    }
    @name("egress.setf2") action setf2(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.setf2") action setf2_3(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.setf2") action setf2_4(bit<32> val) {
        hdr.data.f2 = val;
    }
    @name("egress.alpha") table alpha_0 {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2();
            @defaultonly NoAction_23();
        }
        default_action = NoAction_23();
    }
    @name("egress.beta") table beta_0 {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2_3();
            @defaultonly NoAction_24();
        }
        default_action = NoAction_24();
    }
    @name("egress.gamma") table gamma_0 {
        key = {
            hdr.data.f2: exact @name("hdr.data.f2") ;
        }
        actions = {
            setf2_4();
            @defaultonly NoAction_25();
        }
        default_action = NoAction_25();
    }
    apply {
        alpha_0.apply();
        beta_0.apply();
        gamma_0.apply();
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

