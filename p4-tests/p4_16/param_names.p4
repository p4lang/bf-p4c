#include <core.p4>
#include <v1model.p4>

// This is a P4 program that parses an ethernet header, matches on the ingress
// port, and sets the egress port.  It has an associated STF test and is
// suitable as a starting point for writing more complicated tests.

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
    out packet_t parser_hdrs,
    inout user_metadata_t parser_user_md,
    inout standard_metadata_t parser_standard_md)
{
    state start {
        b.extract(parser_hdrs.data);
        transition accept;
    }
}

control ingress(
    inout packet_t ingress_hdrs,
    inout user_metadata_t ingress_user_md,
    inout standard_metadata_t ingress_standard_md)
{
    action nop() { }
    action set_port(bit<9> port) { ingress_standard_md.egress_spec = port; }

    table t {
        key = { ingress_standard_md.ingress_port : exact; }
        actions = { nop; set_port; }
        default_action = set_port(1); }

    apply { t.apply(); }
}

control egress(
    inout packet_t egress_hdrs,
    inout user_metadata_t egress_user,
    inout standard_metadata_t egress_meta)
{
    apply { }
}

control deparser(packet_out b, in packet_t deparser_hdrs) {
    apply {
        b.emit(deparser_hdrs.data);
    }
}

control vck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

V1Switch(p(), vck(), ingress(), egress(), uck(), deparser()) main;
