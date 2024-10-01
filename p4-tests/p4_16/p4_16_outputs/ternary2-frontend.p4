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

header extra_h {
    bit<16> h;
    bit<8>  b1;
    bit<8>  b2;
}

struct packet_t {
    data_h     data;
    extra_h[4] extra;
}

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta) {
    state start {
        b.extract<data_h>(hdrs.data);
        transition extra;
    }
    state extra {
        b.extract<extra_h>(hdrs.extra.next);
        transition select(hdrs.extra.last.b2) {
            8w0x80 &&& 8w0x80: extra;
            default: accept;
        }
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    @name("setb1") action setb1_0(bit<9> port, bit<8> val) {
        hdrs.data.b1 = val;
        meta.egress_spec = port;
    }
    @name("noop") action noop_0() {
    }
    @name("setbyte") action setbyte_0(out bit<8> reg_0, bit<8> val) {
        reg_0 = val;
    }
    @name("act1") action act1_0(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    @name("act2") action act2_0(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    @name("act3") action act3_0(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    @name("test1") table test1_0 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            setb1_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("ex1") table ex1_0 {
        key = {
            hdrs.extra[0].h: ternary @name("hdrs.extra[0].h") ;
        }
        actions = {
            setbyte_0(hdrs.extra[0].b1);
            act1_0();
            act2_0();
            act3_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("tbl1") table tbl1_0 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_0(hdrs.data.b2);
            noop_0();
        }
        default_action = noop_0();
    }
    @name("tbl2") table tbl2_0 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_0(hdrs.extra[1].b1);
            noop_0();
        }
        default_action = noop_0();
    }
    @name("tbl3") table tbl3_0 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_0(hdrs.extra[2].b2);
            noop_0();
        }
        default_action = noop_0();
    }
    apply {
        test1_0.apply();
        switch (ex1_0.apply().action_run) {
            act1_0: {
                tbl1_0.apply();
            }
            act2_0: {
                tbl2_0.apply();
            }
            act3_0: {
                tbl3_0.apply();
            }
        }

    }
}

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    apply {
        b.emit<packet_t>(hdrs);
    }
}

Switch<packet_t>(p(), ingress(), egress(), deparser()) main;
