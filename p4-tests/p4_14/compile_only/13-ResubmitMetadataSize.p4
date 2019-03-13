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
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        f5 : 32;
        f6 : 32;
        f7 : 32;
        f8 : 32;
    }
}

metadata metadata_t meta;

field_list l1 {
    meta.f1;
    meta.f2;
    meta.f3;
    meta.f4;
    meta.f5;
    meta.f6;
    meta.f7;
    meta.f8;
}
    
action a1(d1, d2, d3, d4, d5, d6, d7, d8) {
    modify_field(meta.f1, d1);
    modify_field(meta.f2, d2);
#if 1
    modify_field(meta.f3, d3);
    modify_field(meta.f4, d4);
    modify_field(meta.f5, d5);
    modify_field(meta.f6, d6);
    modify_field(meta.f7, d7);
    modify_field(meta.f8, d8);
#endif
    resubmit(l1);
}

table t1 {
    actions {
        a1;
    }
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(t1);
    }
}


control egress {
}
