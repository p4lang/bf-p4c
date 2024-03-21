#include <core.p4>
#include <v1model.p4>

// This is a P4 program that parses an ethernet header, matches on the ingress
// port, and sets the egress port.  It tests whether slices of header fields can
// be added together.

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct packet_t {
    ethernet_t data;
}

struct user_metadata_t { }

parser p(
    packet_in b,
    out packet_t hdrs,
    inout user_metadata_t user,
    inout standard_metadata_t meta)
{
    state start {
        b.extract(hdrs.data);
        transition accept;
    }
}

control ingress(
    inout packet_t hdrs,
    inout user_metadata_t user,
    inout standard_metadata_t meta)
{
    action nop() { }
    action set_port(bit<9> port) {
        meta.egress_spec = port;
        hdrs.data.dstAddr[15:0] = hdrs.data.dstAddr[15:0] + hdrs.data.etherType;
    }

    table t {
        key = { meta.ingress_port : exact; }
        actions = { nop; set_port; }
        default_action = set_port(1); }

    apply { t.apply(); }
}

control egress(
    inout packet_t hdrs,
    inout user_metadata_t user,
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
