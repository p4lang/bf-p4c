#include <core.p4>
#include <v1model.p4>

typedef bit<48> MacAddr_t;
typedef bit<9> PortId_t;

// By default, ingress_port is placed in a 16 bit container, we use pragma to
// force it into a 32 bit container. This causes the digest to be packed with
// 'holes' since it is read in network order. This tests the bit/byte offsets
// generated for 'learn_quanta' in context.json are correct for such a scenario.
// P4C-2006
@pa_container_size("ingress", "ig_intr_md.ingress_port", 32)

header Ethernet_t {
    MacAddr_t dmac;
    MacAddr_t smac;
    bit<16> ethertype;
}

struct Headers {
    Ethernet_t ethernet;
}

struct Meta { }

parser p(packet_in b, out Headers h,
         inout Meta m, inout standard_metadata_t sm) {
    state start {
        b.extract(h.ethernet);
        transition accept;
    }
}

control vrfy(inout Headers h, inout Meta m) { apply {} }
control update(inout Headers h, inout Meta m) { apply {} }

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    apply {}
}

control deparser(packet_out b, in Headers h) {
    apply {
        b.emit(h.ethernet);
    }
}

struct L2_digest {
    MacAddr_t smac;
    PortId_t ig_port;
}

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    direct_counter(CounterType.packets) pkt_counters;
    action send_digest() {
        pkt_counters.count();
        digest<L2_digest>(1, {h.ethernet.smac, sm.ingress_port});
    }
    action nop() {
        pkt_counters.count();
    }
    table smac {
        key = { h.ethernet.smac : exact; }
        actions = { send_digest; nop; }
        const default_action = send_digest();
        size = 4096;
        support_timeout = true;
        counters = pkt_counters;
    }
    apply { smac.apply(); sm.egress_spec = sm.ingress_port; }
}

V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
