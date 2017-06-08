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

header_type metadata_t {
    fields {
        field1 : 1;
        field2 : 1;
    }
}

metadata metadata_t md;

parser start {
    extract(ethernet);
    return ingress;
}


action action1_1(value) {
    modify_field(md.field1, value);
}

action action2_1(value) {
    modify_field(md.field2, value);
}

action action1() {
    action1_1(0);
}

action action2() {
    action1_1(1);
}

table dmac1 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action1;
        action2;
    }
    size: 16536;
}

table dmac2 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action2_1;
    }
    size: 16536;
}


control ingress {
    apply(dmac1);
    apply(dmac2);
}

control egress {
}
