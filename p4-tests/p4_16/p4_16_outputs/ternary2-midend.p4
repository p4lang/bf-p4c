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
    @name("noop") action noop_5() {
    }
    @name("noop") action noop_6() {
    }
    @name("noop") action noop_7() {
    }
    @name("noop") action noop_8() {
    }
    @name("setbyte") action setbyte_0(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    @name("setbyte") action setbyte_4(bit<8> val) {
        hdrs.data.b2 = val;
    }
    @name("setbyte") action setbyte_5(bit<8> val) {
        hdrs.extra[1].b1 = val;
    }
    @name("setbyte") action setbyte_6(bit<8> val) {
        hdrs.extra[2].b2 = val;
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
    @name("test1") table test1 {
        key = {
            hdrs.data.f1: ternary @name("hdrs.data.f1") ;
        }
        actions = {
            setb1_0();
            noop_0();
        }
        default_action = noop_0();
    }
    @name("ex1") table ex1 {
        key = {
            hdrs.extra[0].h: ternary @name("hdrs.extra[0].h") ;
        }
        actions = {
            setbyte_0();
            act1_0();
            act2_0();
            act3_0();
            noop_5();
        }
        default_action = noop_5();
    }
    @name("tbl1") table tbl1 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_4();
            noop_6();
        }
        default_action = noop_6();
    }
    @name("tbl2") table tbl2 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_5();
            noop_7();
        }
        default_action = noop_7();
    }
    @name("tbl3") table tbl3 {
        key = {
            hdrs.data.f2: ternary @name("hdrs.data.f2") ;
        }
        actions = {
            setbyte_6();
            noop_8();
        }
        default_action = noop_8();
    }
    apply {
        test1.apply();
        switch (ex1.apply().action_run) {
            act1_0: {
                tbl1.apply();
            }
            act2_0: {
                tbl2.apply();
            }
            act3_0: {
                tbl3.apply();
            }
        }

    }
}

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    @hidden action act() {
        b.emit<data_h>(hdrs.data);
        b.emit<extra_h>(hdrs.extra[0]);
        b.emit<extra_h>(hdrs.extra[1]);
        b.emit<extra_h>(hdrs.extra[2]);
        b.emit<extra_h>(hdrs.extra[3]);
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
