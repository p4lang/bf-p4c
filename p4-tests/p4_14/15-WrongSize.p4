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

header ethernet_t ethernet;

header_type m1_t {
    fields {
        f1  : 1;
    }
}

metadata m1_t m1;

parser start {
    extract(ethernet);
    return ingress;
}

action a1() {                                                      \
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m1.f1);      \
}

table t1 {
    actions {
        a1;
    }
}

control ingress {
    apply(t1);
}

control egress {
}
