#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        a : 32;
        b : 32;
        c : 16;
        d : 16;
        e : 8;
        f : 8;
    }
}

header_type meta_t {
    fields {
        x_12 : 12;
        y_4 : 4;
        z_16 : 16;
    }
}


parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(pkt);
    return ingress;
}

header pkt_t pkt;
metadata meta_t meta;

action do_nothing(){}

action set_meta(){
    modify_field(meta.x_12, 7);
    modify_field(meta.y_4, 15);
    modify_field(meta.z_16, 3);
}

action add_2(){
    add(pkt.c, pkt.c, meta.x_12);
}

action sub_2(){
    add(pkt.c, pkt.d, meta.x_12);
}


table t1 {
    reads {
         pkt.a : exact;
    }
    actions {
         set_meta;
         do_nothing;
    }
    size : 4096;
}

table t2 {
    reads {
         pkt.b : exact;
    }
    actions {
         add_2;
         sub_2;
         do_nothing;
    }
    size : 4096;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress { }