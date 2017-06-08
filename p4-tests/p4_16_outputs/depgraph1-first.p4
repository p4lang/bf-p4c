#include <core.p4>

struct standard_metadata {
    bit<9>  ingress_port;
    bit<32> packet_length;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<16> egress_instance;
    bit<32> instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
}

parser parse<H>(packet_in packet, out H headers, inout standard_metadata meta);
control pipe<H>(inout H headers, inout standard_metadata meta);
control deparse<H>(packet_out packet, in H headers, inout standard_metadata meta);
package Switch<H>(parse<H> p, pipe<H> ig, pipe<H> eg, deparse<H> dep);
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

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta) {
    state start {
        b.extract<data_h>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
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

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    apply {
        b.emit<data_h>(hdrs.data);
    }
}

Switch<packet_t>(p(), ingress(), egress(), deparser()) main;
