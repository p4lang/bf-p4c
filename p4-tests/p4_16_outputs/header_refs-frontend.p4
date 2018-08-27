#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct packet_t {
    ethernet_t data;
}

struct Leaf1 {
    bit<8> f1;
}

struct Leaf2 {
    bit<8> f2;
}

struct Node1 {
    Leaf1 x;
}

struct Node2 {
    Leaf2 x;
}

struct user_metadata_t {
    Node1 n1;
    Node2 n2;
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    state start {
        b.extract<ethernet_t>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    @name("ingress.nop") action nop_0() {
    }
    @name("ingress.set_port") action set_port_0(bit<9> port) {
        meta.egress_spec = port;
    }
    @name("ingress.t") table t {
        key = {
            meta.ingress_port: exact @name("meta.ingress_port") ;
            user.n2.x.f2     : exact @name("user.n2.x.f2") ;
            user.n1.x.f1     : exact @name("user.n1.x.f1") ;
        }
        actions = {
            nop_0();
            set_port_0();
        }
        default_action = set_port_0(9w1);
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
        b.emit<ethernet_t>(hdrs.data);
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

