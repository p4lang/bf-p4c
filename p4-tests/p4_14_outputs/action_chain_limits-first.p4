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
    @name(".seth1") action seth1(bit<16> h1) {
        hdr.data.h1 = h1;
    }
    @name(".seth2") action seth2(bit<16> h2) {
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
    @name(".setb2") action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    @name(".setb3") action setb3(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name(".setb4") action setb4(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name(".setb5") action setb5(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name(".setb6") action setb6(bit<8> b6) {
        hdr.data.b6 = b6;
    }
    @name(".setb7") action setb7(bit<8> b7) {
        hdr.data.b7 = b7;
    }
    @name(".setb8") action setb8(bit<8> b8) {
        hdr.data.b8 = b8;
    }
    @name(".setb9") action setb9(bit<8> b9) {
        hdr.data.b9 = b9;
    }
    @name(".set_port") table set_port {
        actions = {
            port_set();
            noop();
        }
        key = {
            hdr.data.f1: ternary @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t1_0") table t1_0 {
        actions = {
            seth1();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t1_1") table t1_1 {
        actions = {
            seth1();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t2_0") table t2_0 {
        actions = {
            seth2();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t2_1") table t2_1 {
        actions = {
            seth2();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t3_1") table t3_1 {
        actions = {
            seth3();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t4_1") table t4_1 {
        actions = {
            seth4();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t5_1") table t5_1 {
        actions = {
            seth5();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t6_1") table t6_1 {
        actions = {
            seth6();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t7_1") table t7_1 {
        actions = {
            seth7();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t8_1") table t8_1 {
        actions = {
            seth8();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".t9_1") table t9_1 {
        actions = {
            seth9();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".tchain_0") table tchain_0 {
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
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    @name(".tchain_1") table tchain_1 {
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
            noop();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = noop();
    }
    apply {
        switch (tchain_0.apply().action_run) {
            setb1: {
                t1_0.apply();
            }
            default: {
                t2_0.apply();
            }
        }

        switch (tchain_1.apply().action_run) {
            setb1: {
                t1_1.apply();
            }
            setb2: {
                t2_1.apply();
            }
            setb3: {
                t3_1.apply();
            }
            setb4: {
                t4_1.apply();
            }
            setb5: {
                t5_1.apply();
            }
            setb6: {
                t6_1.apply();
            }
            setb7: {
                t7_1.apply();
            }
            setb8: {
                t8_1.apply();
            }
            setb9: {
                t9_1.apply();
            }
        }

        set_port.apply();
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

