#include "tofino/intrinsic_metadata.p4"

#ifndef FP_PORT_2
#if __TARGET_TOFINO__ == 2
// Default ports for Tofino2 have offset 8
#define FP_PORT_2 10
#else
#define FP_PORT_2 2
#endif
#endif

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action nop() { }

action do() { modify_field(ig_intr_md_for_tm.ucast_egress_port, FP_PORT_2); }

table t {
    reads { ig_intr_md.ingress_port : exact; }
    actions { nop; do; }
    default_action : do;
}

control ingress { apply(t); }
