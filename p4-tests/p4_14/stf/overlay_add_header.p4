#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header_type wire_t {
    fields {
        foo : 16; } }

header_type cpu_t {
    fields {
        foo : 16; } }

header ethernet_t ethernet;
header cpu_t cpu;
header wire_t wire;

header_type metadata_t {
    fields {
        port : 9;
        bar : 16; } }

metadata metadata_t md;

parser start {
    extract(ethernet);
    return select(ethernet.ethertype) {
        0x81 : parse_cpu;
        0x82 : parse_wire;
        default : ingress;
    }
}

parser parse_cpu {
    extract(cpu);
    return ingress;
}

parser parse_wire {
    extract(wire);
    return ingress;
}

// Should always forward to port 0
action fwd() {
    modify_field(standard_metadata.egress_spec, md.port);
}

// Prevent constant propagation
action write_bar(val) {
    modify_field(md.bar, val);
}

// Force ethertype and foo to be in the same cluster,
// which will in turn allow eager overlaying
action read_bar_1() {
    // XXX: If wire.foo and cpu.foo are overlaid, compilation will fail
    // trying to write two different values to the same container in the
    // same action.
    modify_field(wire.foo, md.bar);
    add_header(cpu);
    modify_field(cpu.foo, 0);
}

action read_bar_2() {
    modify_field(cpu.foo, md.bar);
}

table write_bar_t {
    actions { write_bar; }
}

table read_bar_1_t {
    reads { ethernet.ethertype : exact; }
    actions { read_bar_1; }
}

table read_bar_2_t {
    reads { ethernet.ethertype : exact; }
    actions { read_bar_2; }
}

table forward {
    reads { ethernet.ethertype : exact; }
    actions { fwd; }
    default_action : fwd;
    size : 128;
}

control ingress {
    apply(write_bar_t);
    apply(read_bar_1_t);
    apply(read_bar_2_t);
    apply(forward);
}

control egress {
}
