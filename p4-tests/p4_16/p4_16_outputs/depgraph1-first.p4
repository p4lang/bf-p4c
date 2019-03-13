#include <core.p4>
#include <v1model.p4>

header data_h {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct packet_t {
    data_h data;
}

struct user_metadata_t {
    bit<8> unused;
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    state start {
        b.extract<data_h>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    action set_f1(bit<32> val) {
        hdrs.data.f1 = val;
    }
    action set_f2(bit<32> val) {
        hdrs.data.f2 = val;
    }
    action set_h1(bit<16> val) {
        hdrs.data.h1 = val;
    }
    action set_b1(bit<8> val) {
        hdrs.data.b1 = val;
    }
    action set_b2(bit<8> val) {
        hdrs.data.b2 = val;
    }
    action set_port(bit<9> port) {
        meta.egress_spec = port;
    }
    action noop() {
    }
    action set_f1_b1_port(bit<32> f1, bit<8> b1, bit<9> port) {
        set_f1(f1);
        set_b1(b1);
        set_port(port);
    }
    table t1 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            set_f2();
            noop();
        }
        default_action = noop();
    }
    table t2 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            set_b1();
            noop();
        }
        default_action = noop();
    }
    table t3 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1();
            noop();
        }
        default_action = noop();
    }
    table t4 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1_b1_port();
            noop();
        }
        default_action = noop();
    }
    apply {
        t1.apply();
        t2.apply();
        t3.apply();
        t4.apply();
    }
}

control egress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs) {
    apply {
        b.emit<data_h>(hdrs.data);
    }
}

control vck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

V1Switch<packet_t, user_metadata_t>(p(), vck(), ingress(), egress(), uck(), deparser()) main;

