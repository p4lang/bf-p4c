#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 16;
        b : 16;
        c : 16;
        d : 16;
        e : 32;
    }
}

header_type meta_t {
    fields { 
        pad : 4;
        w : 1;
        x : 1;
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

action a0(){
    modify_field(hdr1.a, 1);
    modify_field(meta.x, 1);
}

action a1(){
    modify_field(hdr1.a, 2);
    modify_field(meta.y, 1);
}

action a2(){
    modify_field(hdr1.a, 2);
}

table t0 {
    reads {
         hdr1.b : ternary;
    }
    actions {
         a0;
         do_nothing;
    }
    default_action : do_nothing;
    size : 512;
}

table t1 {
    reads {
         hdr1.a : ternary;
         meta.x : exact;
    }
    actions {
         a1;
         do_nothing;
    }
    default_action : do_nothing;
    size : 512;
}

table t2 {
    reads {
         hdr1.b : ternary;
         meta.w : exact;  /* never written */
    }
    actions {
         a2;
         do_nothing;
    }
    default_action : do_nothing;
    size : 512;
}

control ingress {
    apply(t0);
    apply(t1);
    apply(t2);
}

control egress { }