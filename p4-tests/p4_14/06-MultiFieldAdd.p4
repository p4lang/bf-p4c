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
        field1 : 4;
        field2 : 4;
    }
}

metadata metadata_t md;

@pragma pa_solitary ingress md.field1
@pragma pa_solitary ingress md.field2

action action1(val1, val2) {
    add_to_field(md.field1, val1);
    add_to_field(md.field2, val2);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action1;
    }
    size : 131072;
}

control ingress {
    apply(dmac);
}

control egress {
}
