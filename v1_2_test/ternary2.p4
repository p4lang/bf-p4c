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
    bit<8>      b;
    bit<8>      more;
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
        transition select(hdrs.extra.last.more) {
            8w0: accept;
            default: extra;
        }
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    action setb1(bit<9> port, bit<8> val) {
        hdrs.data.b1 = val;
        meta.egress_spec = port;
    }
    action noop() { }

    table test1() {
        key = { hdrs.data.f1 : ternary; }
        actions = {
            setb1;
            noop;
        }
    }

    apply {
        test1.apply();
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
