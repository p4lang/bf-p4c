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

struct user_metadata_t {
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    state start {
        b.extract<ethernet_t>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t user, inout standard_metadata_t meta) {
    @name("ingress.nop") action nop() {
    }
    @name("ingress.set_port") action set_port(bit<9> port) {
        meta.egress_spec = port;
        hdrs.data.dstAddr[15:0] = hdrs.data.dstAddr[15:0] + hdrs.data.etherType;
    }
    @name("ingress.t") table t_0 {
        key = {
            meta.ingress_port: exact @name("meta.ingress_port") ;
        }
        actions = {
            nop();
            set_port();
        }
        default_action = set_port(9w1);
    }
    apply {
        t_0.apply();
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

