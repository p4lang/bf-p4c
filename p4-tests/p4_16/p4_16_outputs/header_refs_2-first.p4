#include <core.p4>
#include <v1model.p4>

header h_t {
    bit<8> f1;
}

struct packet_t {
    h_t data;
}

struct m_t {
    bit<8> f1;
}

struct user_metadata_t {
    m_t data;
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    state start {
        b.extract<h_t>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    action nop() {
    }
    action set_port(bit<9> port) {
        meta.egress_spec = port;
    }
    table t {
        key = {
            meta.ingress_port: exact @name("meta.ingress_port") ;
            user.data.f1     : exact @name("user.data.f1") ;
            hdrs.data.f1     : exact @name("hdrs.data.f1") ;
        }
        actions = {
            nop();
            set_port();
        }
        default_action = set_port(9w1);
    }
    apply {
        t.apply();
    }
}

control egress(inout packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs) {
    apply {
        b.emit<h_t>(hdrs.data);
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

