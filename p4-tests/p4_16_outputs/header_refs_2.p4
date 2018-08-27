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
        b.extract(hdrs.data);
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
            meta.ingress_port: exact;
            user.data.f1     : exact;
            hdrs.data.f1     : exact;
        }
        actions = {
            nop;
            set_port;
        }
        default_action = set_port(1);
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
        b.emit(hdrs.data);
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

V1Switch(p(), vck(), ingress(), egress(), uck(), deparser()) main;

