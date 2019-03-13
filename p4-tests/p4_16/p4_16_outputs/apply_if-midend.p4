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
    @name("ingress.set_port") action set_port(bit<9> port) {
        meta.egress_spec = port;
    }
    @name("ingress.set_f1") action set_f1(bit<32> val) {
        hdrs.data.f1 = val;
        meta.egress_spec = 9w2;
    }
    @name("ingress.noop") action noop() {
    }
    @name("ingress.noop") action noop_2() {
    }
    @name("ingress.t1") table t1_0 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            set_port();
            noop();
        }
        default_action = noop();
    }
    @name("ingress.t2") table t2_0 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            set_f1();
            noop_2();
        }
        default_action = noop_2();
    }
    apply {
        t1_0.apply();
        if (hdrs.data.f2 == 32w0) 
            t2_0.apply();
    }
}

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    @hidden action act() {
        b.emit<data_h>(hdrs.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

Switch<packet_t>(p(), ingress(), egress(), deparser()) main;

