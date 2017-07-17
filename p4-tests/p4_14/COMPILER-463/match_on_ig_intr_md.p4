// Test program for enhancement to use ig_intr_md in the parser for branching
// Compiler-216

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/pktgen_headers.p4>
#endif

header_type ethernet_t { fields { ethernet: 96; } }
header ethernet_t ethernet;
header_type fabric_header_t { fields { fabric : 40; } }
header fabric_header_t fabric_header;

parser start {
    return select(ig_intr_md.ingress_port) {
        0x0000 mask 0x0001 : parse_ethernet;
        0x0001 mask 0x0001 : parse_fabric_header;
        default : parse_ethernet;
    }
}

parser parse_fabric_header {
    extract(ethernet);
    extract(fabric_header);
    return ingress;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

// Tables
action fwd_to_fabric() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 3);
}

action fwd_to_server() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 4);
}

action fwd_drop() {
    drop();
}

table fwd_packet {
    reads {
        ethernet : valid;
        fabric_header : valid;
    }
    actions {
        fwd_to_fabric;
        fwd_to_server;
        fwd_drop;
    }
    size : 4;
}

control ingress {
    apply(fwd_packet);
}
