#include <v1model.p4>

header data_h {
    bit<32> f;
}

struct packet_t {
    data_h  data;
    bit<8>  meta;
}

struct user_metadata_t {
    bit<8> unused;
}

parser p(
    packet_in b,
    out packet_t hdrs,
    inout user_metadata_t m,
    inout standard_metadata_t meta)
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

control ingress(
    inout packet_t hdrs,
    inout user_metadata_t m,
    inout standard_metadata_t meta)
{
    action set(bit<9> port, bit<32> val) {
        hdrs.data.f = val;
        meta.egress_spec = port;
    }
    action noop() { }

    table test1 {
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

control egress(
    inout packet_t hdrs,
    inout user_metadata_t m,
    inout standard_metadata_t meta)
{
    apply { }
}

control deparser(packet_out b, in packet_t hdrs) {
    apply {
        b.emit(hdrs.data);
    }
}

control vck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

V1Switch(p(), vck(), ingress(), egress(), uck(), deparser()) main;
