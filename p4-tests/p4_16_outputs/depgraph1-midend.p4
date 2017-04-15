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
    @name("set_f1") action set_f1_0(bit<32> val) {
        hdrs.data.f1 = val;
    }
    @name("set_f2") action set_f2_0(bit<32> val) {
        hdrs.data.f2 = val;
    }
    @name("set_b1") action set_b1_0(bit<8> val) {
        hdrs.data.b1 = val;
    }
    @name("noop") action noop_0() {
    }
    @name("noop") action noop_4() {
    }
    @name("noop") action noop_5() {
    }
    @name("noop") action noop_6() {
    }
    @name("set_f1_b1_port") action set_f1_b1_port_0(bit<32> f1, bit<8> b1, bit<9> port) {
        hdrs.data.f1 = f1;
        hdrs.data.b1 = b1;
        meta.egress_spec = port;
    }
    @name("t1") table t1 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            set_f2_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("t2") table t2 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            set_b1_0();
            noop_4();
        }
        default_action = noop_4();
    }
    @name("t3") table t3 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1_0();
            noop_5();
        }
        default_action = noop_5();
    }
    @name("t4") table t4 {
        key = {
            hdrs.data.h1: ternary @name("hdrs.data.h1") ;
        }
        actions = {
            set_f1_b1_port_0();
            noop_6();
        }
        default_action = noop_6();
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
