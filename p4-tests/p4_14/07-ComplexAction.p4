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

header_type metadata_t {
    fields {
        field1 : 8;
        field2 : 8;
    }
}

metadata metadata_t md;

action action1() {
    add_to_field(md.field1, md.field2);
    modify_field(md.field2, 5);
}

table table1 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action1;
    }
}

control ingress {
    apply(table1);
}

control egress {
}
