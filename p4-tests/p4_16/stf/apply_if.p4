#include "tofino.h"

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct packet_t {
    data_h      data;
}

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta)
{
    state start {
        b.extract(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    action set_port(bit<9> port) { meta.egress_spec = port; }
    action set_f1(bit<32> val) { hdrs.data.f1 = val; set_port(2); }
    action noop() { }

    table t1 {
        key = { hdrs.data.f1 : ternary; }
        actions = { set_port; noop; }
        default_action = noop; }

    table t2 {
        key = { hdrs.data.f1 : ternary; }
        actions = { set_f1; noop; }
        default_action = noop; }

    apply {
        t1.apply();
        if (hdrs.data.f2 == 0) {
            t2.apply(); } }
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
