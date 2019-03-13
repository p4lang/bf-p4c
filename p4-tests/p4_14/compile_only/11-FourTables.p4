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

parser start {
    extract(ethernet);
    return ingress;
}

header_type ingress_metadata_t {
    fields {
        field1 : 1;
        field2 : 1;
        field3 : 1;
        field4 : 1;
    }
} 

metadata ingress_metadata_t ing_metadata;

action nop() {
}

action action1() {
    modify_field(ing_metadata.field1, 1);
}

action action2() {
    modify_field(ing_metadata.field2, 1);
}

action action3() {
    modify_field(ing_metadata.field3, 1);
}

action action4(newAddr) {
    modify_field(ethernet.srcAddr, newAddr);
}

table table1 {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        action1;
        action2;
    }
}

table table2 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action3;
    }
}

table table3 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action3;
    }
}

table table4 {
    reads {
        ethernet.ethertype : exact;
    }
    actions {
        action4;
    }
}

control ingress {
    apply(table1) {
        action1 { apply(table2); }
        action2 { apply(table3); }
    }
    apply(table4);
}

control egress {
}
