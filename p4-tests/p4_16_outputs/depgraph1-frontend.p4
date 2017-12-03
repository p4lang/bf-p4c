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
    @name("set_f1") action set_f1_0(bit<32> val) {
        hdrs.data.f1 = val;
    }
    @name("set_f2") action set_f2_0(bit<32> val) {
        hdrs.data.f2 = val;
    }
    @name("set_b1") action set_b1_0(bit<8> val) {
        hdrs.data.b1 = val;
    }
    @name("set_port") action set_port_0(bit<9> port_0) {
        meta.egress_spec = port_0;
    }
    @name("noop") action noop_0() {
    }
    @name("set_f1_b1_port") action set_f1_b1_port_0(bit<32> f1, bit<8> b1, bit<9> port) {
        set_f1_0(f1);
        set_b1_0(b1);
        set_port_0(port);
    }
    @name("t1") table t1_0 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            set_f2_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("t2") table t2_0 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            set_b1_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("t3") table t3_0 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("t4") table t4_0 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1_b1_port_0();
            noop_0();
        }
        default_action = noop_0();
    }
    apply {
        t1_0.apply();
        t2_0.apply();
        t3_0.apply();
        t4_0.apply();
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

