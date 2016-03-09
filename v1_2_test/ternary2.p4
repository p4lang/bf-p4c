#include "tofino.h"

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

header extra_h {
    bit<16>     h;
    bit<8>      b1;
    bit<8>      b2;
}

struct packet_t {
    data_h      data;
    extra_h[4]  extra;
}

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta)
{
    state start {
        b.extract(hdrs.data);
        transition extra;
    }
    state extra {
        b.extract(hdrs.extra.next);
        transition select(hdrs.extra.last.b2) {
            8w0x80 &&& 8w0x80: extra;
            default: accept;
        }
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    action setb1(bit<9> port, bit<8> val) {
        hdrs.data.b1 = val;
        meta.egress_spec = port;
    }
    action noop() { }
    action setbyte(out bit<8> reg, bit<8> val) {
        reg = val;
    }
    action act1(bit<8> val) { hdrs.extra[0].b1 = val; }
    action act2(bit<8> val) { hdrs.extra[0].b1 = val; }
    action act3(bit<8> val) { hdrs.extra[0].b1 = val; }

    table test1() {
        key = { hdrs.data.f1 : ternary; }
        actions = {
            setb1;
            noop;
        }
    }
    table ex1() {
        key = { hdrs.extra[0].h : ternary; }
        actions = {
            setbyte(hdrs.extra[0].b1);
            act1;
            act2;
            act3;
            noop;
        }
    }
    table tbl1() {
        key = { hdrs.data.f2 : ternary; }
        actions = { setbyte(hdrs.data.b2); noop; } }
    table tbl2() {
        key = { hdrs.data.f2 : ternary; }
        actions = { setbyte(hdrs.extra[1].b1); noop; } }
    table tbl3() {
        key = { hdrs.data.f2 : ternary; }
        actions = { setbyte(hdrs.extra[2].b2); noop; } }

    apply {
        test1.apply();
        switch (ex1.apply().action_run) {
            act1: { tbl1.apply(); }
            act2: { tbl2.apply(); }
            act3: { tbl3.apply(); }
        }
    }
}

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply { }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    apply {
        b.emit(hdrs.data);
    }
}

Switch(p(), ingress(), egress(), deparser()) main;
