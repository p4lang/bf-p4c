#include "tofino/intrinsic_metadata.p4"

#ifndef FP_PORT_2
#define FP_PORT_2 2
#endif

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type metadata_t {
    fields {
        f1 : 8;
        f2 : 8;
    }
}

header ethernet_t ethernet;
metadata metadata_t m;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
	return ingress;
}

action nop() { }

action do1() {
    modify_field(m.f1, 2);
}

action do2() {
    modify_field(m.f2, 3);
}

table t1 {
    reads { ig_intr_md.ingress_port : exact; }
    actions { do1; do2; }
    default_action : do1();
}

action set_port() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m.f1);
}

table t2 {
    reads {
        m.f1 : exact;
        m.f2 : exact;
    }
    actions { set_port; }
    default_action : set_port();
}

control ingress {
    apply(t1);
    apply(t2);
}
