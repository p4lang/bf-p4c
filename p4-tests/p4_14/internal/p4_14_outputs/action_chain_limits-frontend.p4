#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<8>  b6;
    bit<8>  b7;
    bit<8>  b8;
    bit<8>  b9;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<16> h5;
    bit<16> h6;
    bit<16> h7;
    bit<16> h8;
    bit<16> h9;
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
    @name(".port_set") action port_set(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_14() {
    }
    @name(".noop") action noop_15() {
    }
    @name(".noop") action noop_16() {
    }
    @name(".noop") action noop_17() {
    }
    @name(".noop") action noop_18() {
    }
    @name(".noop") action noop_19() {
    }
    @name(".noop") action noop_20() {
    }
    @name(".noop") action noop_21() {
    }
    @name(".noop") action noop_22() {
    }
    @name(".noop") action noop_23() {
    }
    @name(".noop") action noop_24() {
    }
    @name(".noop") action noop_25() {
    }
    @name(".noop") action noop_26() {
    }
    @name(".seth1") action seth1(bit<16> h1) {
        hdr.data.h1 = h1;
    }
    @name(".seth1") action seth1_2(bit<16> h1) {
        hdr.data.h1 = h1;
    }
    @name(".seth2") action seth2(bit<16> h2) {
        hdr.data.h2 = h2;
    }
    @name(".seth2") action seth2_2(bit<16> h2) {
        hdr.data.h2 = h2;
    }
    @name(".seth3") action seth3(bit<16> h3) {
        hdr.data.h3 = h3;
    }
    @name(".seth4") action seth4(bit<16> h4) {
        hdr.data.h4 = h4;
    }
    @name(".seth5") action seth5(bit<16> h5) {
        hdr.data.h5 = h5;
    }
    @name(".seth6") action seth6(bit<16> h6) {
        hdr.data.h6 = h6;
    }
    @name(".seth7") action seth7(bit<16> h7) {
        hdr.data.h7 = h7;
    }
    @name(".seth8") action seth8(bit<16> h8) {
        hdr.data.h8 = h8;
    }
    @name(".seth9") action seth9(bit<16> h9) {
        hdr.data.h9 = h9;
    }
    @name(".setb1") action setb1(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name(".setb1") action setb1_2(bit<8> b1) {
        hdr.data.b1 = b1;
    }
    @name(".setb2") action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name(".setb2") action setb2_2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name(".setb3") action setb3(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name(".setb3") action setb3_2(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name(".setb4") action setb4(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name(".setb4") action setb4_2(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name(".setb5") action setb5(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name(".setb5") action setb5_2(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name(".setb6") action setb6(bit<8> b6) {
        hdr.data.b6 = b6;
    }
    @name(".setb6") action setb6_2(bit<8> b6) {
        hdr.data.b6 = b6;
    }
    @name(".setb7") action setb7(bit<8> b7) {
        hdr.data.b7 = b7;
    }
    @name(".setb7") action setb7_2(bit<8> b7) {
        hdr.data.b7 = b7;
    }
    @name(".setb8") action setb8(bit<8> b8) {
        hdr.data.b8 = b8;
    }
    @name(".setb8") action setb8_2(bit<8> b8) {
        hdr.data.b8 = b8;
    }
    @name(".setb9") action setb9(bit<8> b9) {
        hdr.data.b9 = b9;
    }
    @name(".setb9") action setb9_2(bit<8> b9) {
        hdr.data.b9 = b9;
    }
    @name(".set_port") table set_port_0 {
        actions = {
            port_set();
            noop();
        }
        key = {
            hdr.data.f1: ternary @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t1_0") table t1 {
        actions = {
            seth1();
            noop_14();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_14();
    }
    @name(".t1_1") table t1_2 {
        actions = {
            seth1_2();
            noop_15();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_15();
    }
    @name(".t2_0") table t2 {
        actions = {
            seth2();
            noop_16();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_16();
    }
    @name(".t2_1") table t2_2 {
        actions = {
            seth2_2();
            noop_17();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_17();
    }
    @name(".t3_1") table t3 {
        actions = {
            seth3();
            noop_18();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_18();
    }
    @name(".t4_1") table t4 {
        actions = {
            seth4();
            noop_19();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_19();
    }
    @name(".t5_1") table t5 {
        actions = {
            seth5();
            noop_20();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_20();
    }
    @name(".t6_1") table t6 {
        actions = {
            seth6();
            noop_21();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_21();
    }
    @name(".t7_1") table t7 {
        actions = {
            seth7();
            noop_22();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_22();
    }
    @name(".t8_1") table t8 {
        actions = {
            seth8();
            noop_23();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_23();
    }
    @name(".t9_1") table t9 {
        actions = {
            seth9();
            noop_24();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_24();
    }
    @name(".tchain_0") table tchain {
        actions = {
            setb1();
            setb2();
            setb3();
            setb4();
            setb5();
            setb6();
            setb7();
            setb8();
            setb9();
            noop_25();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_25();
    }
    @name(".tchain_1") table tchain_2 {
        actions = {
            setb1_2();
            setb2_2();
            setb3_2();
            setb4_2();
            setb5_2();
            setb6_2();
            setb7_2();
            setb8_2();
            setb9_2();
            noop_26();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop_26();
    }
    apply {
        switch (tchain.apply().action_run) {
            setb1: {
                t1.apply();
            }
            default: {
                t2.apply();
            }
        }

        switch (tchain_2.apply().action_run) {
            setb1_2: {
                t1_2.apply();
            }
            setb2_2: {
                t2_2.apply();
            }
            setb3_2: {
                t3.apply();
            }
            setb4_2: {
                t4.apply();
            }
            setb5_2: {
                t5.apply();
            }
            setb6_2: {
                t6.apply();
            }
            setb7_2: {
                t7.apply();
            }
            setb8_2: {
                t8.apply();
            }
            setb9_2: {
                t9.apply();
            }
        }

        set_port_0.apply();
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

