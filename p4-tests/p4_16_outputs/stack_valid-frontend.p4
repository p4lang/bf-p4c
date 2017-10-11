#include <core.p4>
#include <v1model.p4>

header data_h {
    bit<16> f;
}

struct packet_t {
    data_h[2] data;
}

struct user_metadata_t {
    bit<8> unused;
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    state start {
        b.extract<data_h>(hdrs.data[0]);
        b.extract<data_h>(hdrs.data[1]);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    @name("set_port") action set_port_0(bit<9> port) {
        meta.egress_spec = port;
    }
    @name("t") table t_0 {
        key = {
            hdrs.data[0].f: exact @name("hdrs.data[0].f") ;
        }
        actions = {
            set_port_0();
        }
        default_action = set_port_0(9w1);
    }
    @name("do_push") action do_push_0() {
        hdrs.data.push_front(1);
    }
    @name("do_pop") action do_pop_0() {
        hdrs.data.pop_front(1);
    }
    @name("push") table push_0 {
        key = {
        }
        actions = {
            do_push_0();
        }
        default_action = do_push_0();
    }
    @name("pop") table pop_0 {
        key = {
        }
        actions = {
            do_pop_0();
        }
        default_action = do_pop_0();
    }
    apply {
        push_0.apply();
        pop_0.apply();
        if (!hdrs.data[1].isValid()) 
            t_0.apply();
        else 
            set_port_0(9w2);
    }
}

control egress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs) {
    apply {
        b.emit<data_h>(hdrs.data[0]);
        b.emit<data_h>(hdrs.data[1]);
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
