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
header ethernet_t ethernet;

header_type metadata_t {
    fields {
        f1 : 16;
        f2 : 16;
    }
}
metadata metadata_t m;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    set_metadata(m.f1, 0x1);
    set_metadata(m.f2, 0x2);
	return ingress;
}

action nop() { }
action do() { modify_field(ig_intr_md_for_tm.ucast_egress_port, FP_PORT_2); }
table t {
    reads { ig_intr_md.ingress_port : exact; }
    actions { nop; do; }
    default_action : do();
}

action read_f1() { modify_field(ethernet.etherType, m.f1); }
action read_f2() { modify_field(ethernet.etherType, m.f2); }
table set_etherType {
    reads { ig_intr_md.ingress_port : exact; }
    actions {
        read_f1;
        read_f2;
    }
    default_action : read_f1();
}

control ingress {
    apply(t);
    apply(set_etherType);
}
