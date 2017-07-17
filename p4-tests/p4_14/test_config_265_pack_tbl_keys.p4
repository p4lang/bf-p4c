#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 8;
        b : 16;
        c : 8;
    }
}

header_type meta_t {
    fields {
        w : 1;
        x : 1;
        pad : 4;
        y : 1;
        z : 1;
    }
}


parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    return ingress;
}

header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}

action set_meta(x, z){
    modify_field(meta.w, 1);
    modify_field(meta.x, x);
    modify_field(meta.y, 0);
    modify_field(meta.z, z);
}

action set_pkt(b){
    modify_field(hdr1.b, b);
}

table t1 {
    reads {
         hdr1.a : exact;
    }
    actions {
         set_meta;
         do_nothing;
    }
    size : 4096;
}

table t2 {
    reads {
         meta.w : ternary;
         meta.x : exact;
         meta.y : exact;
         meta.z : exact;
    }
    actions {
         set_pkt;
         do_nothing;
    }
    size : 4096;
}


control ingress {
    apply(t1);
    apply(t2);
}

control egress { }