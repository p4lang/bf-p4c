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
    bit<32> f;
}

struct packet_t {
    data_h data;
    bit<8> meta;
}

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta) {
    state start {
        hdrs.meta = 8w0x1;
        b.extract<data_h>(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    @name("set") action set_0(bit<9> port, bit<32> val) {
        hdrs.data.f = val;
        meta.egress_spec = port;
    }
    @name("noop") action noop_0() {
    }
    @name("test1") table test1_0() {
        key = {
            hdrs.meta: ternary @name("hdrs.meta") ;
        }
        actions = {
            set_0();
            noop_0();
        }
        default_action = set_0(9w2, 32w0);
    }
    apply {
        test1_0.apply();
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
