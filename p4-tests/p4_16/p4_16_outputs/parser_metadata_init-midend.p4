#include <core.p4>
#include <v1model.p4>

header data_h {
    bit<32> f;
}

struct packet_t {
    data_h data;
    bit<8> meta;
}

struct user_metadata_t {
    bit<8> unused;
}

parser p(packet_in b, out packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    state start {
        hdrs.meta = 8w0x1;
        b.extract<data_h>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    @name("ingress.set") action set_1(bit<9> port, bit<32> val) {
        hdrs.data.f = val;
        meta.egress_spec = port;
    }
    @name("ingress.noop") action noop() {
    }
    @name("ingress.test1") table test1_0 {
        key = {
            hdrs.meta: ternary @name("hdrs.meta") ;
        }
        actions = {
            set_1();
            noop();
        }
        default_action = set_1(9w2, 32w0);
    }
    apply {
        test1_0.apply();
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

