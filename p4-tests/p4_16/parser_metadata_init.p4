#include "tofino.h"

header data_h {
    bit<32> f;
}

struct packet_t {
    data_h  data;
    bit<8>  meta;
}

parser p(packet_in b, out packet_t hdrs, inout standard_metadata meta)
{
    state start {
        hdrs.meta = 0x01;
        transition get_data;
    }

    state get_data {
        b.extract(hdrs.data);
        transition accept;
    }
}

control ingress(inout packet_t hdrs, inout standard_metadata meta) {
    action set(bit<9> port, bit<32> val) {
        hdrs.data.f = val;
        meta.egress_spec = port;
    }
    action noop() { }

    table test1() {
        key = { hdrs.meta : ternary; }
        actions = {
            set;
            noop;
        }
        default_action = set(2, 0);
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
